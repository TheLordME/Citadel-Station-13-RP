/mob/living/silicon/pai/death(gibbed)
	delete_all_holograms()
	if(card)
		card.removePersonality()
		src.loc = get_turf(card)
		qdel(card)
	if(mind)
		qdel(mind)
	..(gibbed)
	ghostize()
	qdel(src)
