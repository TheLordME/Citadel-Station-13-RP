/datum/category_item/catalogue/fauna/horror/bradley
	name = "&$IT*^^!SEES#"
	desc = "%WARNING% PROCESSING FAILURE! RETURN SCANNER TO A CENTRAL \
	ADMINISTRATOR FOR IMMEDIATE MAINTENANCE! %ERROR%"
	value = CATALOGUER_REWARD_TRIVIAL

/mob/living/simple_mob/horror/bradley
	name = "Bradley"
	desc = "What you see is a ball of seemingly melty flesh, stitched together hastily over large, bulging scars. Four metal legs extend out of its sides, The two in the front are larger than the back; and all of the legs are segmented with a unique steel looking metal. In the middle of this monstrosity is a constantly tremmoring eye. While the eye never blinks, it is dyed faintly yellow, with a vertical, read pupil. It seems like it's crying, a weird, oil like liquid seeping from its socket."

	icon_state = "Bradley"
	icon_living = "Bradley"
	icon_dead = "b_head"
	icon_rest = "Bradley"
	icon = 'icons/mob/horror_show/GHPS.dmi'
	icon_gib = "generic_gib"
	catalogue_data = list(/datum/category_item/catalogue/fauna/horror/bradley)

	attack_sound = 'sound/h_sounds/holla.ogg'

	maxHealth = 175
	health = 175

	legacy_melee_damage_lower = 25
	legacy_melee_damage_upper = 35
	grab_resist = 100

	response_help = "pets the"
	response_disarm = "bops the"
	response_harm = "hits the"
	attacktext = list("mutilate")
	friendly = list("nuzzles", "eyeboops", "headbumps against", "leans on")


	say_list_type = /datum/say_list/bradley
	ai_holder_type = /datum/ai_holder/polaris/simple_mob/horror

	bone_amount = 4
	hide_amount = 2
	exotic_amount = 5

/mob/living/simple_mob/horror/bradley/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/horror_aura/weak)

/mob/living/simple_mob/horror/bradley/death()
	playsound(src, 'sound/h_sounds/mumble.ogg', 50, 1)
	..()

/mob/living/simple_mob/horror/bradley/on_bullet_act(obj/projectile/proj, impact_flags, list/bullet_act_args)
	. = ..()
	playsound(src, 'sound/h_sounds/holla.ogg', 50, 1)

/mob/living/simple_mob/horror/bradley/attack_hand(mob/user, datum/event_args/actor/clickchain/e_args)
	playsound(src, 'sound/h_sounds/holla.ogg', 50, 1)
	..()

/mob/living/simple_mob/horror/bradley/throw_impacted(atom/movable/AM, datum/thrownthing/TT)
	. = ..()
	playsound(src, 'sound/h_sounds/holla.ogg', 50, 1)

/mob/living/simple_mob/horror/bradley/attackby()
	playsound(src, 'sound/h_sounds/holla.ogg', 50, 1)
	..()

/datum/say_list/bradley
	speak = list("Uuurrgh?","Aauuugghh...", "AAARRRGH!")
	emote_hear = list("shrieks through its skin", "groans in pain", "creaks", "clanks")
	emote_see = list("taps its limbs against the ground", "shakes", "stares aggressively")
	say_maybe_target = list("Uuurrgghhh?")
	say_got_target = list("AAAHHHHH!")
