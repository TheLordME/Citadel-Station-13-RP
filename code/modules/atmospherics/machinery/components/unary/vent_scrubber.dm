/obj/machinery/atmospherics/component/unary/vent_scrubber
	icon = 'icons/atmos/vent_scrubber.dmi'
	icon_state = "map_scrubber_off"
	pipe_state = "scrubber"

	name = "Air Scrubber"
	desc = "Has a valve and pump attached to it"
	use_power = USE_POWER_OFF
	idle_power_usage = 150		//internal circuitry, friction losses and stuff
	power_rating = 7500			//7500 W ~ 10 HP

	connect_types = CONNECT_TYPE_REGULAR|CONNECT_TYPE_SCRUBBER //connects to regular and scrubber pipes

	level = 1

	/// registered area
	var/area/registered_area
	/// auto name by area
	var/name_from_area = TRUE
	/// show on area
	var/controllable_from_alarm = TRUE

	var/area_uid
	var/id_tag = null

	var/frequency = 1439
	var/datum/radio_frequency/radio_connection

	var/hibernate = 0 //Do we even process?
	var/scrubbing = 1 //0 = siphoning, 1 = scrubbing
	var/list/scrubbing_gas = list(GAS_ID_CARBON_DIOXIDE, GAS_ID_PHORON)

	var/panic = 0 //is this scrubber panicked?

	var/radio_filter_out
	var/radio_filter_in

#warn groups

/obj/machinery/atmospherics/component/unary/vent_scrubber/Initialize(mapload)
	. = ..()
	air_contents.volume = ATMOS_DEFAULT_VOLUME_FILTER

	for(var/id in scrubbing_gas)
		if(!global.gas_data.gases[id])
			scrubbing_gas -= id
			stack_trace("Invalid gas id [id]")

	icon = null
	registered_area = get_area(loc)
	area_uid = registered_area.uid
	registered_area?.register_scrubber(src)
	if (!id_tag)
		assign_uid()
		id_tag = num2text(uid)

/obj/machinery/atmospherics/component/unary/vent_scrubber/Destroy()
	unregister_radio(src, frequency)
	registered_area?.unregister_scrubber(src)
	return ..()

/obj/machinery/atmospherics/component/unary/vent_scrubber/update_icon(safety = 0)
	if(!check_icon_cache())
		return

	cut_overlays()

	var/scrubber_icon = "scrubber"

	var/turf/T = get_turf(src)
	if(!istype(T))
		return

	if(welded)
		scrubber_icon += "weld"
	else if(!powered())
		scrubber_icon += "off"
	else
		scrubber_icon += "[use_power ? "[scrubbing ? "on" : "in"]" : "off"]"

	add_overlay(icon_manager.get_atmos_icon("device", , , scrubber_icon))

/obj/machinery/atmospherics/component/unary/vent_scrubber/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return
		if(!T.is_plating() && node && node.level == 1 && istype(node, /obj/machinery/atmospherics/pipe))
			return
		else
			if(node)
				add_underlay(T, node, dir, node.icon_connect_type)
			else
				add_underlay(T,, dir)

/obj/machinery/atmospherics/component/unary/vent_scrubber/proc/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = radio_controller.add_object(src, frequency, radio_filter_in)

/obj/machinery/atmospherics/component/unary/vent_scrubber/proc/broadcast_status()
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src
	signal.data = list(
		"area" = area_uid,
		"tag" = id_tag,
		"device" = "AScr",
		"timestamp" = world.time,
		"power" = use_power,
		"scrubbing" = scrubbing,
		"panic" = panic,
		"filter_o2" = (GAS_ID_OXYGEN in scrubbing_gas),
		"filter_n2" = (GAS_ID_NITROGEN in scrubbing_gas),
		"filter_co2" = (GAS_ID_CARBON_DIOXIDE in scrubbing_gas),
		"filter_phoron" = (GAS_ID_PHORON in scrubbing_gas),
		"filter_n2o" = (GAS_ID_NITROUS_OXIDE in scrubbing_gas),
		"filter_fuel" = (GAS_ID_VOLATILE_FUEL in scrubbing_gas),
		"sigtype" = "status"
	)

	radio_connection.post_signal(src, signal, radio_filter_out)

	return 1

/obj/machinery/atmospherics/component/unary/vent_scrubber/atmos_init()
	..()
	radio_filter_in = frequency==initial(frequency)?(RADIO_FROM_AIRALARM):null
	radio_filter_out = frequency==initial(frequency)?(RADIO_TO_AIRALARM):null
	if (frequency)
		set_frequency(frequency)
		src.broadcast_status()


/obj/machinery/atmospherics/component/unary/vent_scrubber/proc/can_scrub()
	if(machine_stat & (NOPOWER|BROKEN))
		return 0
	if(!use_power)
		return 0
	if(welded)
		return 0
	return 1


/obj/machinery/atmospherics/component/unary/vent_scrubber/process(delta_time)
	..()

	if (hibernate)
		return 1

	if (!node)
		update_use_power(USE_POWER_OFF)
	//broadcast_status()
	if(!can_scrub())
		return 0

	var/datum/gas_mixture/environment = loc.return_air()

	var/power_draw = -1
	if(scrubbing)
		//limit flow rate from turfs
		var/transfer_moles = min(environment.total_moles, environment.total_moles*MAX_SCRUBBER_FLOWRATE/environment.volume)	//group_multiplier gets divided out here

		power_draw = scrub_gas(src, scrubbing_gas, environment, air_contents, transfer_moles, power_rating)
	else //Just siphon all air
		//limit flow rate from turfs
		var/transfer_moles = min(environment.total_moles, environment.total_moles*MAX_SIPHON_FLOWRATE/environment.volume)	//group_multiplier gets divided out here

		power_draw = pump_gas(src, environment, air_contents, transfer_moles, power_rating)


	if (power_draw >= 0)
		last_power_draw_legacy = power_draw
		use_power(power_draw)

	if(network)
		network.update = 1

	return 1

/obj/machinery/atmospherics/component/unary/vent_scrubber/hide(var/i) //to make the little pipe section invisible, the icon changes.
	update_icon()
	update_underlays()

/obj/machinery/atmospherics/component/unary/vent_scrubber/receive_signal(datum/signal/signal)
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if(!signal.data["tag"] || (signal.data["tag"] != id_tag) || (signal.data["sigtype"]!="command"))
		return 0

	if(signal.data["power"] != null)
		update_use_power(text2num(signal.data["power"]))
	if(signal.data["power_toggle"] != null)
		update_use_power(!use_power)

	if(signal.data["panic_siphon"]) //must be before if("scrubbing" thing
		panic = text2num(signal.data["panic_siphon"])
		if(panic)
			update_use_power(USE_POWER_IDLE)
			scrubbing = 0
		else
			scrubbing = 1
	if(signal.data["toggle_panic_siphon"] != null)
		panic = !panic
		if(panic)
			update_use_power(USE_POWER_IDLE)
			scrubbing = 0
		else
			scrubbing = 1

	if(signal.data["scrubbing"] != null)
		scrubbing = text2num(signal.data["scrubbing"])
		if(scrubbing)
			panic = 0
	if(signal.data["toggle_scrubbing"])
		scrubbing = !scrubbing
		if(scrubbing)
			panic = 0

	var/list/toggle = list()

	if(!isnull(signal.data["o2_scrub"]) && text2num(signal.data["o2_scrub"]) != (GAS_ID_OXYGEN in scrubbing_gas))
		toggle += GAS_ID_OXYGEN
	else if(signal.data["toggle_o2_scrub"])
		toggle += GAS_ID_OXYGEN

	if(!isnull(signal.data["n2_scrub"]) && text2num(signal.data["n2_scrub"]) != (GAS_ID_NITROGEN in scrubbing_gas))
		toggle += GAS_ID_NITROGEN
	else if(signal.data["toggle_n2_scrub"])
		toggle += GAS_ID_NITROGEN

	if(!isnull(signal.data["co2_scrub"]) && text2num(signal.data["co2_scrub"]) != (GAS_ID_CARBON_DIOXIDE in scrubbing_gas))
		toggle += GAS_ID_CARBON_DIOXIDE
	else if(signal.data["toggle_co2_scrub"])
		toggle += GAS_ID_CARBON_DIOXIDE

	if(!isnull(signal.data["tox_scrub"]) && text2num(signal.data["tox_scrub"]) != (GAS_ID_PHORON in scrubbing_gas))
		toggle += GAS_ID_PHORON
	else if(signal.data["toggle_tox_scrub"])
		toggle += GAS_ID_PHORON

	if(!isnull(signal.data["n2o_scrub"]) && text2num(signal.data["n2o_scrub"]) != (GAS_ID_NITROUS_OXIDE in scrubbing_gas))
		toggle += GAS_ID_NITROUS_OXIDE
	else if(signal.data["toggle_n2o_scrub"])
		toggle += GAS_ID_NITROUS_OXIDE

	if(!isnull(signal.data["fuel_scrub"]) && text2num(signal.data["fuel_scrub"]) != (GAS_ID_VOLATILE_FUEL in scrubbing_gas))
		toggle += GAS_ID_VOLATILE_FUEL
	else if(signal.data["toggle_fuel_scrub"])
		toggle += GAS_ID_VOLATILE_FUEL

	scrubbing_gas ^= toggle

	if(signal.data["status"] != null)
		spawn(2)
			broadcast_status()
		return //do not update_icon

//			log_admin("DEBUG \[[world.timeofday]\]: vent_scrubber/receive_signal: unknown command \"[signal.data["command"]]\"\n[signal.debug_print()]")
	spawn(2)
		broadcast_status()
	update_icon()
	return

/obj/machinery/atmospherics/component/unary/vent_scrubber/power_change()
	var/old_stat = machine_stat
	..()
	if(old_stat != machine_stat)
		update_icon()

/obj/machinery/atmospherics/component/unary/vent_scrubber/attackby(var/obj/item/W as obj, var/mob/user as mob)
	if (!W.is_wrench())
		return ..()
	if (!(machine_stat & NOPOWER) && use_power)
		to_chat(user, "<span class='warning'>You cannot unwrench \the [src], turn it off first.</span>")
		return 1
	var/turf/T = src.loc
	if (node && node.level==1 && isturf(T) && !T.is_plating())
		to_chat(user, "<span class='warning'>You must remove the plating first.</span>")
		return 1
	if(unsafe_pressure())
		to_chat(user, "<span class='warning'>You feel a gust of air blowing in your face as you try to unwrench [src]. Maybe you should reconsider..</span>")
	add_fingerprint(user)
	playsound(src, W.tool_sound, 50, 1)
	to_chat(user, "<span class='notice'>You begin to unfasten \the [src]...</span>")
	if (do_after(user, 40 * W.tool_speed))
		user.visible_message( \
			"<span class='notice'>\The [user] unfastens \the [src].</span>", \
			"<span class='notice'>You have unfastened \the [src].</span>", \
			"You hear a ratchet.")
		deconstruct()

/obj/machinery/atmospherics/component/unary/vent_scrubber/examine(mob/user, dist)
	. = ..()
	. += "A small gauge in the corner reads [round(last_flow_rate_legacy, 0.1)] L/s; [round(last_power_draw_legacy)] W"
	if(welded)
		. += "It seems welded shut."

/// Scrubber Welding

/obj/machinery/atmospherics/component/unary/vent_scrubber/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weldingtool))
		var/obj/item/weldingtool/WT = W
		if (WT.remove_fuel(0,user))
			to_chat(user, "<span class='notice'>Now welding the vent.</span>")
			if(do_after(user, 20 * WT.tool_speed))
				if(!src || !WT.isOn()) return
				playsound(src.loc, WT.tool_sound, 50, 1)
				if(!welded)
					user.visible_message("<span class='notice'>\The [user] welds the vent shut.</span>", "<span class='notice'>You weld the vent shut.</span>", "You hear welding.")
					welded = 1
					update_icon()
				else
					user.visible_message("<span class='notice'>[user] unwelds the vent.</span>", "<span class='notice'>You unweld the vent.</span>", "You hear welding.")
					welded = 0
					update_icon()
			else
				to_chat(user, "<span class='notice'>The welding tool needs to be on to start this task.</span>")
		else
			to_chat(user, "<span class='warning'>You need more welding fuel to complete this task.</span>")
			return 1
	else
		..()

/**
 * encodes data for AtmosScrubberControl interface component
 */
/obj/machinery/atmospherics/component/unary/vent_scrubber/proc/ui_scrubber_data()
	return list(

	)
	#warn impl

/obj/machinery/atmospherics/component/unary/vent_scrubber/on
	use_power = USE_POWER_IDLE
	icon_state = "map_scrubber_on"

/obj/machinery/atmospherics/component/unary/vent_scrubber/on/welded
	welded = 1

/obj/machinery/atmospherics/component/unary/vent_scrubber/retro
	icon_state = "map_scrubber_off"	/// Will get replaced on mapload

/obj/machinery/atmospherics/component/unary/vent_scrubber/retro/on
	use_power = USE_POWER_IDLE
	icon_state = "map_scrubber_on"

/obj/machinery/atmospherics/component/unary/vent_scrubber/retro/on/welded
	welded = 1

/obj/machinery/atmospherics/component/unary/vent_scrubber/retro/update_icon(safety = 0)
	if(!check_icon_cache())
		return

	cut_overlays()

	var/scrubber_icon = "scrubber"

	var/turf/T = get_turf(src)
	if(!istype(T))
		return

	if(welded)
		scrubber_icon += "retro_weld"
	else if(!powered())
		scrubber_icon += "retro_off"
	else
		scrubber_icon += "[use_power ? "[scrubbing ? "retro_on" : "retro_in"]" : "retro_off"]"

	add_overlay(icon_manager.get_atmos_icon("device", , , scrubber_icon))
