/**
 * like a rig controll module, but cant be taken off
 */

///ADD_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)
///REMOVE_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)

/obj/item/phoronoid_suit_controller
	name = "Omnisuit Controller"
	desc = "WIP"
	slot_flags = SLOT_BACK
	w_class = ITEMSIZE_NO_CONTAINER
	icon = 'icons/obj/rig_modules.dmi'
	icon_state = "ert_commander_rig"
	//Protections, no extra protections like temp, simens, n'stuff
	armor_type = /datum/armor/hardsuit //Subject to change
	//More to come with modules

	//Who is wearing us
	var/mob/living/carbon/human/human

	unacidable = 1

	//Custom vars
	var/sealed = FALSE
	var/obj/item/clothing/suit/chest_type
	var/obj/item/clothing/head/helmet/space/helm_type
	var/obj/item/clothing/shoes/magboots/hardsuit/boot_type
	var/obj/item/clothing/gloves/gauntlets/hardsuit/glove_type



/obj/item/phoronoid_suit_controller/proc/seal(mob/M)
	var/mob/living/carbon/human/H = M

	if(!H || !istype(H)) return

	if(H.back != src && H.belt != src)
		return

	if(sealed)
		REMOVE_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)
		sealed = FALSE
	else
		ADD_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)
		sealed = TRUE
	to_chat(H, SPAN_NOTICE("[src] has been [sealed ? "":"un"]sealed."))

