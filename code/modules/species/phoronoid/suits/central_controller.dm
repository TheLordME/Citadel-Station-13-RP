/**
 * like a rig controll module, but cant be taken off
 */

#define STATE_OFF 0
#define STATE_POWERSAVE 1
#define STATE_ON 2
#define STATE_HIGHPOWER 3

///ADD_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)
///REMOVE_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)

/obj/item/phoronoid_suit_controller
	name = "Omnisuit Controller"
	desc = "WIP"
	slot_flags = SLOT_BACK
	w_class = ITEMSIZE_NO_CONTAINER

	//Protections, no extra protections like temp, simens, n'stuff
	armor_type = /datum/armor/hardsuit //Subject to change
	//More to come with modules

	unacidable = 1

	//Custom vars
	var/activation_state = STATE_ON

	

#undef STATE_OFF
#undef STATE_POWERSAVE
#undef STATE_ON
#undef STATE_HIGHPOWER
