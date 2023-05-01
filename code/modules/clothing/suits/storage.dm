/obj/item/clothing/suit/storage
	var/obj/item/storage/internal/pockets
	var/slots = 2

/obj/item/clothing/suit/storage/Initialize(mapload)
	. = ..()
	pockets = new/obj/item/storage/internal(src, slots, ITEMSIZE_SMALL)	// Fit only pocket sized items
	pockets.max_w_class = ITEMSIZE_SMALL				// Fit only pocket sized items
	pockets.max_storage_space = ITEMSIZE_COST_SMALL * 2

/obj/item/clothing/suit/storage/Destroy()
	QDEL_NULL(pockets)
	. = ..()

/obj/item/clothing/suit/storage/toggle/AltClick()	// This only works for things that can be toggled, of course.
	..()
	ToggleButtons()

/obj/item/clothing/suit/storage/attack_hand(mob/user, list/params)
	if (pockets.handle_attack_hand(user))
		..(user)

/obj/item/clothing/suit/storage/OnMouseDropLegacy(obj/over_object as obj)
	if (pockets.handle_mousedrop(usr, over_object))
		..(over_object)

/obj/item/clothing/suit/storage/attackby(obj/item/W as obj, mob/user as mob)
	..()
	if(!(W in accessories))		// Make sure that an accessory wasn't successfully attached to suit.
		pockets.attackby(W, user)

/obj/item/clothing/suit/storage/emp_act(severity)
	pockets.emp_act(severity)
	..()

//Jackets with buttons, used for labcoats, IA jackets, First Responder jackets, and brown jackets.
/obj/item/clothing/suit/storage/toggle
	inv_hide_flags = HIDEHOLSTER
	var/open = 0	//0 is closed, 1 is open, -1 means it won't be able to toggle
	action_button_name = "Toggle Coat Buttons"

/obj/item/clothing/suit/storage/toggle/ui_action_click()
	ToggleButtons()

/obj/item/clothing/suit/storage/toggle/proc/ToggleButtons()
	if(open == 1) //Will check whether icon state is currently set to the "open" or "closed" state and switch it around with a message to the user
		open = 0
		icon_state = initial(icon_state)
		inv_hide_flags = HIDETIE|HIDEHOLSTER
		to_chat(usr, "You button up the coat.")
	else if(open == 0)
		open = 1
		icon_state = "[icon_state]_open"
		inv_hide_flags = HIDEHOLSTER
		to_chat(usr, "You unbutton the coat.")
	else //in case some goofy admin switches icon states around without switching the icon_open or icon_closed
		to_chat(usr, "You attempt to button-up the velcro on your [src], before promptly realising how silly you are.")
		return
	update_worn_icon()	//so our overlays update


/obj/item/clothing/suit/storage/hooded/toggle
	inv_hide_flags = HIDEHOLSTER
	var/open = 0	//0 is closed, 1 is open, -1 means it won't be able to toggle

/obj/item/clothing/suit/storage/hooded/toggle/verb/toggle()
	set name = "Toggle Coat Buttons"
	set category = "Object"
	set src in usr
	if(!CHECK_MOBILITY(usr, MOBILITY_CAN_USE))
		return 0

	if(open == 1) //Will check whether icon state is currently set to the "open" or "closed" state and switch it around with a message to the user
		open = 0
		icon_state = initial(icon_state)
		inv_hide_flags = HIDETIE|HIDEHOLSTER
		to_chat(usr, "You button up the coat.")
	else if(open == 0)
		open = 1
		icon_state = "[icon_state]_open"
		inv_hide_flags = HIDEHOLSTER
		to_chat(usr, "You unbutton the coat.")
	else //in case some goofy admin switches icon states around without switching the icon_open or icon_closed
		to_chat(usr, "You attempt to button-up the velcro on your [src], before promptly realising how silly you are.")
		return
	update_worn_icon()	//so our overlays update


//New Vest 4 pocket storage and badge toggles, until suit accessories are a thing.
/obj/item/clothing/suit/storage/vest/heavy/Initialize(mapload)
	. = ..()
	pockets = new/obj/item/storage/internal(src)
	pockets.max_w_class = ITEMSIZE_SMALL
	pockets.max_storage_space = ITEMSIZE_COST_SMALL * 4

/obj/item/clothing/suit/storage/vest
	var/icon_badge
	var/icon_nobadge

/obj/item/clothing/suit/storage/vest/verb/toggle()
	set name ="Adjust Badge"
	set category = "Object"
	set src in usr
	if(!CHECK_MOBILITY(usr, MOBILITY_CAN_USE))
		return 0

	if(icon_state == icon_badge)
		icon_state = icon_nobadge
		to_chat(usr, "You conceal \the [src]'s badge.")
	else if(icon_state == icon_nobadge)
		icon_state = icon_badge
		to_chat(usr, "You reveal \the [src]'s badge.")
	else
		to_chat(usr, "\The [src] does not have a badge.")
		return
	update_worn_icon()
