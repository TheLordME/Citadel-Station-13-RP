/obj/machinery/atmospherics/component/trinary/filter
	name = "gas filter"
	icon = 'icons/atmos/filter.dmi'
	icon_state = "map"
	density = FALSE
	construction_type = /obj/item/pipe/trinary/flippable
	pipe_state = "filter"
	level = 1

	use_power = USE_POWER_IDLE
	idle_power_usage = 150
	power_rating = 7500

	tgui_interface = "AtmosFilterTrinary"

	/// target gas id, or groups
	var/filtering
	// todo: put flow rate at component level
	/// flow rate in L
	var/flow_setting = ATMOS_DEFAULT_VOLUME_FILTER
	/// current flow rate in L
	var/flow_current = 0

/obj/machinery/atmospherics/component/trinary/filter/Initialize(mapload)
	. = ..()
	air1.volume = ATMOS_DEFAULT_VOLUME_FILTER
	air2.volume = ATMOS_DEFAULT_VOLUME_FILTER
	air3.volume = ATMOS_DEFAULT_VOLUME_FILTER

/obj/machinery/atmospherics/component/trinary/filter/update_icon_state()
	if(mirrored)
		icon_state = "m"
	else
		icon_state = ""
	if(!powered())
		icon_state += "off"
	else if(node2 && node3 && node1)
		icon_state += on ? "on" : "off"
	else
		icon_state += "off"
	return ..()

/obj/machinery/atmospherics/component/trinary/filter/process(delta_time)
	..()

	if(!on || inoperable())
		return

	var/old_mols = air1.total_moles
	var/transfer_mols = (flow_setting / air1.volume) * old_mols

	if(transfer_mols > MINIMUM_MOLES_TO_FILTER)
		power_current = xgm_filter_gas(air1, air3, air2, filtering, transfer_mols, power_setting * efficiency_multiplier) / efficiency_multiplier
		flow_current = (1 - air1.total_moles / old_mols) * air1.volume

		// todo: better API for this
		network1?.update = TRUE
		network2?.update = TRUE
		network3?.update = TRUE

	if(power_current)
		use_power(power_current)

/obj/machinery/atmospherics/component/trinary/filter/proc/set_rate(liters)
	flow_setting = clamp(liters, 0, air1.volume)

/obj/machinery/atmospherics/component/trinary/filter/ui_interact(mob/user, datum/tgui/ui, datum/tgui/parent_ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosFilter", name)
		ui.open()

/obj/machinery/atmospherics/component/trinary/filter/ui_data(mob/user)
	. = ..()
	.["filtering"] = filtering
	.["maxRate"] = air1.volume
	.["rate"] = flow_setting

/obj/machinery/atmospherics/component/trinary/filter/ui_static_data(mob/user, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	.["atmosContext"] = global.gas_data.tgui_gas_context()

/obj/machinery/atmospherics/component/trinary/filter/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("filter")
			var/target = params["target"]
			if(!(isnum(target)? global.gas_data.gas_groups_filterable(target) : global.gas_data.gas_id_filterable(target)))
				return FALSE
			filtering = target
			return TRUE
		if("rate")
			var/liters = params["rate"]
			if(isnull(liters))
				return FALSE
			set_rate(liters)
			return TRUE

/obj/machinery/atmospherics/component/trinary/filter/mirrored
	icon_state = "mmap"
	dir = SOUTH
	initialize_directions = SOUTH|NORTH|EAST
	mirrored = TRUE
