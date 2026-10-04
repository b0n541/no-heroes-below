extends Node2D
## Throwaway encounter prototype for the first live playtest.
## In-memory state, one central RNG, deliberately small and easy to revise.

const COLS = 11
const ROWS = 7
const ORIGIN = Vector2(84, 236)
const CELL = Vector2(66, 46)
const PANTRY = Vector2i(10, 3)
const ROCKS = [Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 4), Vector2i(3, 5), Vector2i(8, 0), Vector2i(8, 6)]
const DIRECTIONS = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const INK = Color("eee3c9")
const GOLD = Color("efbd66")
const GREEN = Color("85d7b0")
const RED = Color("f39b8e")
const BLUE = Color("84c9e9")

var rng = RandomNumberGenerator.new()
var units: Array = []
var phase = "preparation"
var round_number = 1
var pantry_hp = 3
var selected = 0
var mode = "move"
var pending: Dictionary = {}
var lure_target = -1
var trap_cell = Vector2i(4, 3)
var trap_state = "unplaced"
var rig_available = true
var busy = false
var hovered = Vector2i(-1, -1)
var log_lines: Array[String] = []
var textures: Dictionary = {}
var manifest: Dictionary = {}
var status_label: Label
var crew_label: Label
var intent_label: Label
var help_label: Label
var preview_label: Label
var log_label: RichTextLabel
var die_label: Label
var confirm_button: Button
var next_button: Button
var action_buttons: Dictionary = {}
var crew_buttons: Array[Button] = []
var font: Font

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	font = ThemeDB.fallback_font
	rng.randomize()
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset-manifest.json")).assets
	for key in manifest:
		textures[key] = load("res://assets/" + manifest[key].path)
	build_ui()
	restart()

func make_label(at: Vector2, dimensions: Vector2, text_size: int, color: Color = INK) -> Label:
	var label = Label.new()
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", text_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func make_button(title: String, at: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var button = Button.new()
	button.text = title
	button.focus_mode = Control.FOCUS_NONE
	button.position = at
	button.size = dimensions
	button.add_theme_font_size_override("font_size", 16)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("263635") if state == "normal" else Color("3c5148")
		if state == "disabled":
			style.bg_color = Color("1f2728")
		style.border_color = GOLD if state in ["focus", "pressed"] else Color("526154")
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", INK)
	button.pressed.connect(callback)
	add_child(button)
	return button

func build_ui() -> void:
	make_label(Vector2(30, 16), Vector2(790, 44), 30, GOLD).text = "WAKING IN THE WARREN"
	make_label(Vector2(31, 61), Vector2(800, 35), 16).text = "Can three fragile kobolds save their home with a whistle, a pit, and a sling?"
	status_label = make_label(Vector2(880, 24), Vector2(365, 74), 21, GOLD)
	make_label(Vector2(31, 111), Vector2(800, 42), 17).text = "Defend the pantry. Defeat both invaders before they steal all 3 supplies."
	make_label(Vector2(38, 159), Vector2(400, 25), 14, BLUE).text = "ENTRANCE →     Stone blocks movement and sight."
	make_label(Vector2(580, 159), Vector2(265, 25), 14, GREEN).text = "← YOUR HOME  /  PANTRY"
	for i in range(3):
		var index = i
		crew_buttons.append(make_button(["1 · Piks", "2 · Mumpf", "3 · Krix"][i], Vector2(880 + i * 122, 121), Vector2(116, 42), func(): select_unit(index)))
	crew_label = make_label(Vector2(880, 176), Vector2(360, 92), 17, GREEN)
	help_label = make_label(Vector2(880, 270), Vector2(360, 119), 16)
	intent_label = make_label(Vector2(880, 397), Vector2(360, 98), 15, RED)
	make_label(Vector2(880, 511), Vector2(220, 28), 17, GOLD).text = "COMBAT LOG"
	die_label = make_label(Vector2(1110, 506), Vector2(130, 40), 22, GOLD)
	log_label = RichTextLabel.new()
	log_label.position = Vector2(880, 545)
	log_label.size = Vector2(360, 263)
	log_label.add_theme_font_size_override("normal_font_size", 15)
	log_label.scroll_following = true
	add_child(log_label)
	preview_label = make_label(Vector2(38, 626), Vector2(800, 78), 17, BLUE)
	var actions = [["move", "Move [M]"], ["attack", "Attack [A]"], ["ability", "Ability [S]"], ["trap", "Place pit [T]"]]
	for i in range(actions.size()):
		var action: String = actions[i][0]
		action_buttons[action] = make_button(actions[i][1], Vector2(30 + i * 158, 719), Vector2(149, 42), func(): choose_mode(action))
	confirm_button = make_button("Confirm [Enter]", Vector2(668, 719), Vector2(174, 42), confirm_action)
	next_button = make_button("Start raid", Vector2(30, 775), Vector2(250, 42), advance_turn)
	make_button("Restart [R]", Vector2(295, 775), Vector2(160, 42), restart)
	make_label(Vector2(478, 779), Vector2(365, 35), 14).text = "Select: 1–3 · Cancel: Esc · End turn: Space"

func new_unit(title: String, key: String, cell: Vector2i, hp: int, ac: int, bonus: int, attack_range: int, speed: int, dex: int, ally: bool) -> Dictionary:
	return {"name": title, "art": key, "cell": cell, "hp": hp, "max_hp": hp, "ac": ac, "bonus": bonus, "range": attack_range, "speed": speed, "dex": dex, "ally": ally, "move": speed, "action": true, "stuck": false, "lure": Vector2i(-1, -1)}

func restart() -> void:
	if busy:
		return
	units = [
		new_unit("Piks", "piks-idle", Vector2i(5, 3), 8, 13, 4, 1, 4, 3, true),
		new_unit("Mumpf", "mumpf-idle", Vector2i(6, 4), 10, 12, 3, 1, 3, 1, true),
		new_unit("Krix", "krix-idle", Vector2i(6, 2), 8, 13, 4, 4, 4, 2, true),
		new_unit("Fighter", "fighter-idle", Vector2i(0, 3), 18, 15, 4, 1, 3, 1, false),
		new_unit("Ranger", "ranger-idle", Vector2i(0, 4), 12, 13, 3, 4, 2, 3, false)]
	phase = "preparation"
	round_number = 1
	pantry_hp = 3
	selected = 0
	mode = "move"
	pending.clear()
	lure_target = -1
	trap_cell = Vector2i(4, 3)
	trap_state = "unplaced"
	rig_available = true
	log_lines.clear()
	die_label.text = "d20 · —"
	add_log("The adventurers are coming. Place the pit, then position your crew on the right side of the cave.")
	refresh()

func add_log(line: String) -> void:
	log_lines.append(line)
	log_label.text = "\n\n".join(log_lines)

func alive(index: int) -> bool:
	return units[index].hp > 0

func cell_center(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell) * CELL + CELL / 2

func valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS and cell not in ROCKS

func unit_at(cell: Vector2i) -> int:
	for i in range(units.size()):
		if alive(i) and units[i].cell == cell:
			return i
	return -1

func distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))

func can_step(start: Vector2i, goal: Vector2i) -> bool:
	if not valid_cell(goal) or distance(start, goal) != 1:
		return false
	var delta = goal - start
	# Diagonal squares cost one movement, but cannot cross a stone corner.
	if delta.x != 0 and delta.y != 0:
		return valid_cell(start + Vector2i(delta.x, 0)) and valid_cell(start + Vector2i(0, delta.y))
	return true

func can_rig(cell: Vector2i) -> bool:
	if not valid_cell(cell) or distance(units[1].cell, cell) > 2:
		return false
	var occupant = unit_at(cell)
	# Resetting our spent pit is allowed under an invader; new placement needs space.
	return occupant < 0 or (occupant >= 3 and cell == trap_cell and trap_state == "triggered")

func path_to(start: Vector2i, goal: Vector2i) -> Array:
	if not valid_cell(goal) or (unit_at(goal) >= 0 and goal != start):
		return []
	var frontier: Array = [start]
	var previous: Dictionary = {start: start}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal:
			break
		for direction in DIRECTIONS:
			var cell: Vector2i = current + direction
			if can_step(current, cell) and unit_at(cell) < 0 and not previous.has(cell):
				previous[cell] = current
				frontier.append(cell)
	if not previous.has(goal):
		return []
	var route: Array = []
	var cursor = goal
	while cursor != start:
		route.push_front(cursor)
		cursor = previous[cursor]
	return route

func can_see(a: Vector2i, b: Vector2i) -> bool:
	var delta = b - a
	var steps = maxi(absi(delta.x), absi(delta.y)) * 4
	for i in range(1, steps):
		var point = Vector2(a) + Vector2(delta) * float(i) / float(steps)
		if Vector2i(roundi(point.x), roundi(point.y)) in ROCKS:
			return false
	return true

func push_destination(attacker: Dictionary, target: Dictionary) -> Vector2i:
	var delta: Vector2i = target.cell - attacker.cell
	var direction = Vector2i(signi(delta.x), 0) if absi(delta.x) >= absi(delta.y) else Vector2i(0, signi(delta.y))
	return target.cell + direction

func attack_preview(attacker: Dictionary, target: Dictionary, stone: bool = false) -> String:
	var extra = ""
	if stone:
		var destination = push_destination(attacker, target)
		extra = " Push to %s." % tile_name(destination) if valid_cell(destination) and unit_at(destination) < 0 else " Push blocked by stone, edge, or a unit."
	return "%s → %s · d20 +%d vs AC %d · range %d/%d · sight clear · normal roll.\nHit: 1d6+%d damage.%s Natural 1 misses; natural 20 rolls 2d6." % [attacker.name, target.name, attacker.bonus, target.ac, distance(attacker.cell, target.cell), attacker.range, 2 if not attacker.ally else 1, extra]

func tile_name(cell: Vector2i) -> String:
	return "%s%d" % [char(65 + cell.x), cell.y + 1]

func select_unit(index: int) -> void:
	if busy or phase in ["won", "lost"] or not alive(index):
		return
	selected = index
	pending.clear()
	lure_target = -1
	mode = "move"
	refresh()

func choose_mode(action: String) -> void:
	if busy or phase in ["won", "lost"]:
		return
	mode = action
	pending.clear()
	lure_target = -1
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hovered = Vector2i((event.position - ORIGIN) / CELL)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point = event.position
		if Rect2(ORIGIN, CELL * Vector2(COLS, ROWS)).has_point(point):
			click_cell(Vector2i((point - ORIGIN) / CELL))
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: select_unit(0)
			KEY_2: select_unit(1)
			KEY_3: select_unit(2)
			KEY_M: choose_mode("move")
			KEY_A: choose_mode("attack")
			KEY_S: choose_mode("ability")
			KEY_T: choose_mode("trap")
			KEY_ENTER: confirm_action()
			KEY_SPACE: advance_turn()
			KEY_R: restart()
			KEY_ESCAPE:
				pending.clear()
				lure_target = -1
				refresh()

func click_cell(cell: Vector2i) -> void:
	if busy or phase in ["won", "lost"]:
		return
	var occupant = unit_at(cell)
	if occupant >= 0 and units[occupant].ally:
		select_unit(occupant)
		return
	pending.clear()
	var actor: Dictionary = units[selected]
	if phase == "preparation":
		if mode == "trap":
			if valid_cell(cell) and occupant < 0 and cell.x >= 2 and cell.x <= 7:
				pending = {"kind": "rig", "cell": cell}
		elif valid_cell(cell) and occupant < 0 and cell.x >= 4 and cell != PANTRY:
			pending = {"kind": "deploy", "cell": cell}
	elif mode == "move" and valid_cell(cell):
		var route = path_to(actor.cell, cell)
		if not route.is_empty() and route.size() <= actor.move:
			pending = {"kind": "move", "cell": cell, "route": route}
	elif actor.action:
		if mode == "attack" or (mode == "ability" and selected == 2):
			if occupant >= 3 and distance(actor.cell, cell) <= actor.range and can_see(actor.cell, cell):
				pending = {"kind": "stone" if mode == "ability" else "attack", "target": occupant}
		elif mode == "ability" and selected == 1 and rig_available:
			if can_rig(cell):
				pending = {"kind": "rig", "cell": cell}
		elif mode == "ability" and selected == 0:
			if occupant >= 3 and distance(actor.cell, cell) <= 6 and can_see(actor.cell, cell):
				lure_target = occupant
			elif lure_target >= 3 and valid_cell(cell) and (occupant < 0 or cell == units[lure_target].cell) and distance(actor.cell, cell) <= 6 and can_see(actor.cell, cell):
				pending = {"kind": "whistle", "target": lure_target, "cell": cell}
	refresh()
	if pending.is_empty() and lure_target < 0:
		if mode == "ability" and selected == 1:
			preview_label.text = "Quick Rig is spent for this raid." if not rig_available else ("Mumpf has already used his action this round." if not actor.action else "Quick Rig needs a free tile or the existing spent pit within 2 squares, including diagonals.")
		else:
			preview_label.text = "That action is unavailable. Check movement, range, sight, occupied cells, and the selected kobold's action."

func confirm_action() -> void:
	if busy or pending.is_empty() or phase in ["won", "lost"]:
		return
	var action = pending.duplicate(true)
	pending.clear()
	var actor: Dictionary = units[selected]
	match action.kind:
		"deploy":
			actor.cell = action.cell
			add_log("%s prepares at %s." % [actor.name, tile_name(action.cell)])
		"rig":
			trap_cell = action.cell
			trap_state = "armed"
			if phase != "preparation":
				actor.action = false
				rig_available = false
			add_log("%s rigs the pit at %s. Dexterity save DC 13; fail: 2d6 damage and lost movement; pass: safe crossing." % [actor.name if phase != "preparation" else "The crew", tile_name(trap_cell)])
			if unit_at(trap_cell) >= 3:
				add_log("The pit is rearmed beneath the invader. It triggers on the next entry; rearming deals no damage.")
		"move":
			actor.move -= action.route.size()
			actor.cell = action.cell
			add_log("%s moves to %s (%d movement left)." % [actor.name, tile_name(actor.cell), actor.move])
		"attack", "stone":
			actor.action = false
			busy = true
			refresh()
			await resolve_attack(selected, action.target, action.kind == "stone")
			busy = false
		"whistle":
			actor.action = false
			units[action.target].lure = action.cell
			add_log("Piks whistles: %s will move toward %s on its next turn, before attacking." % [units[action.target].name, tile_name(action.cell)])
	lure_target = -1
	check_outcome()
	refresh()

func roll_die(sides: int) -> int:
	return rng.randi_range(1, sides)

func reveal_die(value: int, title: String) -> void:
	for face in ["◇", "◈", "◇"]:
		die_label.text = "d20 · " + face
		await get_tree().create_timer(0.07).timeout
	die_label.text = "d20 · %d" % value
	preview_label.text = "%s · d20 shows %d" % [title, value]
	await get_tree().create_timer(0.16).timeout

func attack_hits(natural: int, bonus: int, ac: int) -> bool:
	return natural == 20 or (natural != 1 and natural + bonus >= ac)

func resolve_attack(attacker_index: int, target_index: int, stone: bool = false) -> void:
	var attacker: Dictionary = units[attacker_index]
	var target: Dictionary = units[target_index]
	var natural = roll_die(20)
	await reveal_die(natural, attacker.name + " attacks " + target.name)
	if not attack_hits(natural, attacker.bonus, target.ac):
		add_log("%s → %s: d20 %d +%d = %d vs AC %d. MISS%s." % [attacker.name, target.name, natural, attacker.bonus, natural + attacker.bonus, target.ac, " (natural 1)" if natural == 1 else ""])
		return
	var dice_count = 2 if natural == 20 else 1
	var damage = 1 if attacker.ally else 2
	var rolls: Array[String] = []
	for i in range(dice_count):
		var die = roll_die(6)
		damage += die
		rolls.append(str(die))
	target.hp = maxi(0, target.hp - damage)
	add_log("%s → %s: d20 %d +%d = %d vs AC %d. %s %s+%d = %d damage; %d/%d HP." % [attacker.name, target.name, natural, attacker.bonus, natural + attacker.bonus, target.ac, "CRITICAL!" if natural == 20 else "HIT.", "+".join(rolls), 1 if attacker.ally else 2, damage, target.hp, target.max_hp])
	if target.hp == 0:
		add_log("%s is out of the fight." % target.name)
	elif stone:
		var destination = push_destination(attacker, target)
		if valid_cell(destination) and unit_at(destination) < 0:
			target.cell = destination
			add_log("Stone Shot pushes %s to %s." % [target.name, tile_name(destination)])
			await trigger_pit(target_index)
		else:
			add_log("Stone Shot's push is blocked; the hit still deals damage.")
	queue_redraw()

func trigger_pit(index: int) -> bool:
	if trap_state != "armed" or units[index].cell != trap_cell or units[index].ally:
		return false
	trap_state = "triggered"
	var target: Dictionary = units[index]
	var natural = roll_die(20)
	await reveal_die(natural, target.name + " makes a Dexterity save")
	if natural + target.dex >= 13:
		add_log("Pit: %s rolls d20 %d +%d DEX = %d vs DC 13. SAVE: no damage; keeps moving. The pit is spent." % [target.name, natural, target.dex, natural + target.dex])
		return false
	var first = roll_die(6)
	var second = roll_die(6)
	target.hp = maxi(0, target.hp - first - second)
	target.stuck = true
	add_log("Pit: %s rolls d20 %d +%d DEX = %d vs DC 13. FAIL: %d+%d = %d damage; %d HP. Movement stops; next turn spent climbing." % [target.name, natural, target.dex, natural + target.dex, first, second, first + second, target.hp])
	return true

func advance_turn() -> void:
	if busy or phase in ["won", "lost"]:
		return
	pending.clear()
	lure_target = -1
	if phase == "preparation":
		phase = "kobolds"
		add_log("The raid begins! Each kobold has movement and one action per round. Move and act in either order.")
		refresh()
		return
	busy = true
	phase = "adventurers"
	refresh()
	add_log("— Adventurers · round %d —" % round_number)
	for index in [3, 4]:
		if alive(index):
			await enemy_turn(index)
			check_outcome()
			refresh()
			if phase in ["won", "lost"]:
				break
	if phase not in ["won", "lost"]:
		round_number += 1
		phase = "kobolds"
		for i in range(3):
			units[i].move = units[i].speed
			units[i].action = true
		if not alive(selected):
			for i in range(3):
				if alive(i):
					selected = i
					break
		add_log("— Kobolds · round %d —" % round_number)
	busy = false
	refresh()

func enemy_target(index: int) -> int:
	var enemy: Dictionary = units[index]
	# Ranger first threatens Krix, then Piks, then Mumpf. Fighter seeks lowest HP.
	var priority = [2, 0, 1] if index == 4 else [0, 1, 2]
	var target_index = -1
	for i in priority:
		if alive(i) and distance(enemy.cell, units[i].cell) <= enemy.range and can_see(enemy.cell, units[i].cell):
			if index == 4:
				return i
			if target_index < 0 or units[i].hp < units[target_index].hp:
				target_index = i
	return target_index

func next_enemy_step(index: int, goal: Vector2i) -> Vector2i:
	var route = path_to(units[index].cell, goal)
	if route.is_empty() and unit_at(goal) >= 0:
		var best: Array = []
		for direction in DIRECTIONS:
			var candidate = path_to(units[index].cell, goal + direction)
			if not candidate.is_empty() and (best.is_empty() or candidate.size() < best.size()):
				best = candidate
		route = best
	if not route.is_empty():
		return route[0]
	return units[index].cell

func enemy_turn(index: int) -> void:
	var enemy: Dictionary = units[index]
	if enemy.stuck:
		enemy.stuck = false
		enemy.lure = Vector2i(-1, -1)
		add_log("%s spends this turn climbing out of the pit; no move or attack." % enemy.name)
		return
	var lured: bool = enemy.lure.x >= 0
	var goal: Vector2i = enemy.lure if lured else PANTRY
	if not lured:
		var initial_target = enemy_target(index)
		if initial_target >= 0:
			await resolve_attack(index, initial_target)
			return
	for step in range(enemy.speed):
		if enemy.cell == goal:
			break
		var next_cell = next_enemy_step(index, goal)
		if next_cell == enemy.cell:
			break
		enemy.cell = next_cell
		queue_redraw()
		await get_tree().create_timer(0.16).timeout
		if await trigger_pit(index):
			enemy.lure = Vector2i(-1, -1)
			return
		if not lured and enemy_target(index) >= 0:
			break
	enemy.lure = Vector2i(-1, -1)
	if not alive(index):
		return
	if enemy.cell == PANTRY:
		pantry_hp -= 1
		add_log("%s raids the pantry. %d/3 supplies remain." % [enemy.name, pantry_hp])
	else:
		var target_index = enemy_target(index)
		if target_index >= 0:
			await resolve_attack(index, target_index)
		else:
			add_log("%s advances to %s; no kobold in attack range." % [enemy.name, tile_name(enemy.cell)])

func check_outcome() -> void:
	if phase in ["preparation", "won", "lost"]:
		return
	if pantry_hp <= 0 or (not alive(0) and not alive(1) and not alive(2)):
		phase = "lost"
		add_log("THE WARREN FALLS. " + ("The pantry is empty." if pantry_hp <= 0 else "The crew is knocked out.") + " Restart to try a new defense.")
	elif not alive(3) and not alive(4):
		phase = "won"
		add_log("THE WARREN HOLDS! Both invaders are defeated. %d/3 supplies remain. The kobolds keep their home." % pantry_hp)

func enemy_intent(index: int) -> String:
	if not alive(index):
		return units[index].name + ": defeated"
	var enemy: Dictionary = units[index]
	if enemy.stuck:
		return enemy.name + ": climb out; skip next turn"
	if enemy.lure.x >= 0:
		return "%s: follow whistle → %s" % [enemy.name, tile_name(enemy.lure)]
	var target = enemy_target(index)
	if target >= 0:
		return "%s: attack %s (+%d vs AC %d)" % [enemy.name, units[target].name, enemy.bonus, units[target].ac]
	return "%s: advance to pantry; attack if in range" % enemy.name

func refresh() -> void:
	var actor: Dictionary = units[selected]
	var phase_title = {"preparation": "PREPARE YOUR DEFENSE", "kobolds": "YOUR CREW'S TURN", "adventurers": "ADVENTURERS' TURN", "won": "THE WARREN HOLDS!", "lost": "THE WARREN FALLS"}
	status_label.text = "%s\nRound %d · Pantry %d/3" % [phase_title[phase], round_number, pantry_hp]
	crew_label.text = "%s · HP %d/%d · AC %d\nMove %d/%d · Action %s\nAttack +%d · Range %d" % [actor.name, actor.hp, actor.max_hp, actor.ac, actor.move, actor.speed, "ready" if actor.action else "spent", actor.bonus, actor.range]
	var abilities = ["Whistle: select a visible enemy within 6, then a visible lure tile within 6. It follows before attacking.", "Quick Rig: place or reset the one pit within 2 squares. Reset a spent pit even under an invader; triggers on next entry. One use during the raid.", "Stone Shot: ranged attack within 4; on hit push one tile away. Push an invader onto the pit!"]
	help_label.text = "PREPARATION\nPlace pit, click a free tile, Confirm. Select a kobold and position it on the right. Then Start raid." if phase == "preparation" else abilities[selected] + "\nOne action per round. A normal attack also uses it."
	intent_label.text = "ENEMY INTENT\n" + enemy_intent(3) + "\n" + enemy_intent(4)
	for i in range(3):
		crew_buttons[i].disabled = busy or not alive(i)
		crew_buttons[i].text = ("● " if selected == i else "") + units[i].name + " %d" % units[i].hp
	var ended = phase in ["won", "lost"]
	for action in action_buttons:
		action_buttons[action].disabled = busy or ended or (phase == "preparation" and action in ["attack", "ability"]) or (phase != "preparation" and action == "trap") or (phase != "preparation" and action in ["attack", "ability"] and not actor.action)
		action_buttons[action].modulate = GOLD if mode == action else Color.WHITE
	confirm_button.disabled = busy or ended or pending.is_empty()
	next_button.disabled = busy or ended
	next_button.text = "Start raid · pit " + ("ready" if trap_state == "armed" else "not placed") if phase == "preparation" else "End crew turn [Space]"
	if ended:
		preview_label.text = "Your home is safe. Restart to try another plan." if phase == "won" else "Try luring an invader onto the pit and focusing your crew's attacks. Restart to prepare again."
	elif not pending.is_empty():
		match pending.kind:
			"attack", "stone": preview_label.text = attack_preview(actor, units[pending.target], pending.kind == "stone")
			"move": preview_label.text = "%s → %s: %d movement, %d remains. Blue route avoids stone and occupied cells. Confirm to move." % [actor.name, tile_name(pending.cell), pending.route.size(), actor.move - pending.route.size()]
			"deploy": preview_label.text = "Position %s at %s before the raid. Confirm to place." % [actor.name, tile_name(pending.cell)]
			"rig": preview_label.text = "Pit at %s · DEX save DC 13. Fail: 2d6 damage, stop, spend next turn climbing. Pass: cross safely.\nOne invader triggers it. Kobolds cross safely. Resetting beneath an invader deals no damage; the next entry triggers it. One reset during the raid." % tile_name(pending.cell)
			"whistle": preview_label.text = "Lure %s toward %s on its next turn. Whistle uses Piks's action; no roll. Confirm to whistle." % [units[pending.target].name, tile_name(pending.cell)]
	elif lure_target >= 0:
		preview_label.text = "%s selected for Whistle. Now click a free lure tile within 6 of Piks; choose the pit or a tile beyond it." % units[lure_target].name
	else:
		preview_label.text = "Select an action, then click a highlighted tile or an enemy to preview. Confirm commits the action.\n" + ("Place your pit before starting. You may reposition freely on the right." if phase == "preparation" else "Diagonals cost 1 movement; adjacent diagonals are in melee range. Stone corners block movement.\nGreen = movement · Red diamond = invader · Gold circle = selected kobold.")
	queue_redraw()

func draw_sprite(key: String, ground: Vector2, height: float, flip: bool = false) -> void:
	var asset: Dictionary = manifest[key]
	var bounds: Array = asset.content_rect_px
	var source = Rect2(bounds[0], bounds[1], bounds[2], bounds[3])
	var ratio = height / float(bounds[3])
	var pivot: Array = asset.pivot_px
	var offset = Vector2(float(pivot[0]) - float(bounds[0]), float(pivot[1]) - float(bounds[1])) * ratio
	var dimensions = Vector2(float(bounds[2]), float(bounds[3])) * ratio
	var destination = Rect2(ground - offset, dimensions)
	if flip:
		destination.position.x = ground.x - (dimensions.x - offset.x)
		destination.size.x = -dimensions.x
	draw_texture_rect_region(textures[key], destination, source)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 850), Color("111c22"))
	draw_rect(Rect2(863, 108, 390, 715), Color("1a292d"))
	draw_rect(Rect2(25, 616, 828, 90), Color("1a292d"))
	if textures.is_empty() or units.is_empty():
		return
	draw_texture_rect(textures["cave-background"], Rect2(25, 190, 828, 415), false, Color("c2c9c4"))
	var actor: Dictionary = units[selected]
	for y in range(ROWS):
		for x in range(COLS):
			var cell = Vector2i(x, y)
			var rectangle = Rect2(ORIGIN + Vector2(cell) * CELL, CELL)
			var tint = Color(0.12, 0.17, 0.18, 0.18)
			if cell in ROCKS:
				tint = Color(0.12, 0.17, 0.19, 0.9)
			elif not busy and phase not in ["won", "lost"]:
				if phase == "preparation" and mode == "trap" and x >= 2 and x <= 7 and unit_at(cell) < 0:
					tint = Color(0.94, 0.69, 0.28, 0.26)
				elif phase == "preparation" and mode != "trap" and x >= 4 and unit_at(cell) < 0 and cell != PANTRY:
					tint = Color(0.27, 0.72, 0.51, 0.18)
				elif phase == "kobolds" and mode == "move" and unit_at(cell) < 0:
					var route = path_to(actor.cell, cell)
					if not route.is_empty() and route.size() <= actor.move:
						tint = Color(0.27, 0.72, 0.51, 0.27)
				elif phase == "kobolds" and mode == "ability" and actor.action:
					if selected == 1 and rig_available and can_rig(cell):
						tint = Color(0.94, 0.69, 0.28, 0.3)
					elif selected == 0 and lure_target >= 0 and unit_at(cell) < 0 and distance(actor.cell, cell) <= 6 and can_see(actor.cell, cell):
						tint = Color(0.94, 0.69, 0.28, 0.3)
			draw_rect(rectangle.grow(-1), tint)
			draw_rect(rectangle.grow(-1), Color(0.83, 0.78, 0.64, 0.25), false, 1)
			if cell in ROCKS:
				draw_string(font, rectangle.position + Vector2(10, 29), "STONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("8c9695"))
			if cell == hovered:
				draw_rect(rectangle.grow(-2), BLUE, false, 2)
	for x in range(COLS):
		draw_string(font, ORIGIN + Vector2(x * CELL.x + 28, -8), char(65 + x), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
	for y in range(ROWS):
		draw_string(font, ORIGIN + Vector2(-19, y * CELL.y + 29), str(y + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
	var pantry_center = cell_center(PANTRY)
	draw_rect(Rect2(pantry_center - Vector2(25, 18), Vector2(50, 35)), Color("735333"))
	draw_rect(Rect2(pantry_center - Vector2(25, 18), Vector2(50, 35)), GOLD, false, 2)
	draw_string(font, pantry_center + Vector2(-20, 6), "%d / 3" % pantry_hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD)
	draw_string(font, pantry_center + Vector2(-28, 38), "PANTRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	if trap_state != "unplaced":
		draw_sprite("pit-armed" if trap_state == "armed" else "pit-triggered", cell_center(trap_cell), 38)
		draw_string(font, cell_center(trap_cell) + Vector2(-21, 26), "DC 13" if trap_state == "armed" else "SPENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	if pending.has("route"):
		var last = cell_center(actor.cell)
		for cell in pending.route:
			draw_line(last, cell_center(cell), BLUE, 3)
			last = cell_center(cell)
	if pending.has("cell"):
		draw_rect(Rect2(ORIGIN + Vector2(pending.cell) * CELL, CELL).grow(-2), GOLD, false, 3)
	var order: Array = range(units.size())
	order.sort_custom(func(a, b): return units[a].cell.y < units[b].cell.y)
	for i in order:
		if not alive(i):
			continue
		var unit: Dictionary = units[i]
		var center = cell_center(unit.cell)
		var ground = center + Vector2(0, 16)
		if unit.ally:
			draw_arc(center + Vector2(0, 11), 22, 0, TAU, 28, GOLD if selected == i else GREEN, 3)
		else:
			var diamond = PackedVector2Array([center + Vector2(0, -17), center + Vector2(28, 9), center + Vector2(0, 25), center + Vector2(-28, 9), center + Vector2(0, -17)])
			draw_polyline(diamond, RED, 2)
			if pending.get("target", -1) == i or lure_target == i:
				draw_arc(center, 30, 0, TAU, 28, GOLD, 3)
		draw_sprite(unit.art, ground, 63 if unit.ally else 78, not unit.ally)
		draw_rect(Rect2(ground + Vector2(-24, 1), Vector2(48, 5)), Color("402e2c"))
		draw_rect(Rect2(ground + Vector2(-24, 1), Vector2(48.0 * unit.hp / unit.max_hp, 5)), GREEN if unit.ally else RED)
		draw_string(font, ground + Vector2(-27, 20), "%s %d" % [unit.name, unit.hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
