/obj/machinery/power/transformer
	name = "Power Transformer"
	desc = "A century old design to seperate grids from one another."
	var/obj/machinery/power/terminal/terminal = null
	var/efficency = 0.95 //Power efficency, its gonna change if I ever follow through with my metalurgy ideas
	var/available = 0
	var/target = 0
	var/building_terminal = FALSE


/obj/machinery/power/transformer/proccess()
	var/drawn = 0
	var/loss = 0

	available = terminal?.powernet?.last_surplus()
	var/last_excess = powernet.netexcess // This is from the output side
	var/to_draw = (target/efficency) - last_excess //Energy still remaining in the powergrid

	if(to_draw > 0)
		drawn = terminal?.powernet?.draw_power(to_draw)
		loss = drawn * (1 - efficency)
		add_avail(drawn - loss)

	else if(to_draw < 0)// if the excess is large enough, feed it back through the transformer
		loss = abs(to_draw) * (1 - efficency)
		terminal.add_avail(abs(to_draw) * efficency)//As long as efficency is <= 1 this is a stable/declining oscillation

	var/datum/gas_mixture/env = loc.return_air()
	env?.adjust_thermal_energy(loss)

/obj/machinery/power/transformer/Initialize(mapload, newdir)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/power/transformer/LateInitialize()
	. = ..()
	dir_loop:
		for(var/d in GLOB.cardinal)
			var/turf/T = get_step(src, d)
			for(var/obj/machinery/power/terminal/term in T)
				if(term && term.dir == turn(d, 180))
					terminal = term
					break dir_loop
	if(!terminal)
		machine_stat |= BROKEN
		return
	terminal.master = src
	if(!terminal.powernet)
		terminal.connect_to_network()

/obj/machinery/power/transformer/disconnect_terminal()
	if(terminal)
		terminal.master = null
		terminal = null
		return 1
	return 0

/obj/machinery/power/transformer/proc/make_terminal(const/mob/user)
	if (user.loc == loc)
		to_chat(user, "<span class='warning'>You must not be on the same tile as the [src].</span>")
		return 1

	//Direction the terminal will face to
	var/tempDir = get_dir(user, src)
	switch(tempDir)
		if (NORTHEAST, SOUTHEAST)
			tempDir = EAST
		if (NORTHWEST, SOUTHWEST)
			tempDir = WEST
	var/turf/tempLoc = get_step(src, global.reverse_dir[tempDir])
	if (istype(tempLoc, /turf/space))
		to_chat(user, "<span class='warning'>You can't build a terminal on space.</span>")
		return 1
	else if (istype(tempLoc))
		if(!tempLoc.is_plating())
			to_chat(user, "<span class='warning'>You must remove the floor plating first.</span>")
			return 1
	to_chat(user, "<span class='notice'>You start adding cable to the [src].</span>")
	if(do_after(user, 50))
		terminal = new /obj/machinery/power/terminal(tempLoc)
		terminal.setDir(tempDir)
		terminal.master = src
		terminal.connect_to_network()
		return 0
	return 1

/obj/machinery/power/transformer/attackby(var/obj/item/W as obj, var/mob/user as mob)
	if(istype(W, /obj/item/stack/cable_coil) && !terminal && !building_terminal)
		building_terminal = 1
		var/obj/item/stack/cable_coil/CC = W
		if (CC.get_amount() < 10)
			to_chat(user, "<span class='warning'>You need more cables.</span>")
			building_terminal = 0
			return 0
		if (make_terminal(user))
			building_terminal = 0
			return 0
		building_terminal = 0
		CC.use(10)
		user.visible_message(\
				"<span class='notice'>[user.name] has added cables to the [src].</span>",\
				"<span class='notice'>You added cables to the [src].</span>")
		machine_stat = NONE
		return 0

	else if(W.is_wirecutter() && terminal && !building_terminal)
		building_terminal = 1
		var/turf/tempTDir = terminal.loc
		if (istype(tempTDir))
			if(!tempTDir.is_plating())
				to_chat(user, "<span class='warning'>You must remove the floor plating first.</span>")
			else
				to_chat(user, "<span class='notice'>You begin to cut the cables...</span>")
				playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, 1)
				if(do_after(user, 50 * W.tool_speed))
					if (prob(50) && electrocute_mob(usr, terminal.powernet, terminal))
						var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
						s.set_up(5, 1, src)
						s.start()
						building_terminal = 0
						if(!CHECK_MOBILITY(usr, MOBILITY_CAN_USE))
							return 0
					new /obj/item/stack/cable_coil(loc,10)
					user.visible_message(\
						"<span class='notice'>[user.name] cut the cables and dismantled the power terminal.</span>",\
						"<span class='notice'>You cut the cables and dismantle the power terminal.</span>")
					qdel(terminal)
		building_terminal = 0
		return 0
	return 1
