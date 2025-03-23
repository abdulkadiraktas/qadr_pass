# Seaon Pass Creator

A simple web application to create and manage season passes with qadr_ui

# Explore qadr_ui

[Docs](https://abdulkadir-aktas.gitbook.io/qadr_docs/qadr_ui)

[Buy](https://west-world.tebex.io/package/5165474)

[Forum](https://forum.cfx.re/t/paid-qadr-ui-standalone/4872625)

Video Play List :
https://www.youtube.com/watch?v=LxdI-Ez4pVE&list=PLchFjqoahGcmI997Gtbue4o6GhGtPrGpR&index=1

## Features

- Create a pass by selecting a template
- Set the pass details
- Customize the visual settings
- View the pass history
- Delete a pass
- Edit a pass


## Screenshots

![Pass Creator General](.gitimages/pass_creator_general.png)

![Pass Creator Item Reward](.gitimages/pass_creator_item_reward.png)

![Pass Creator Visual Settings](.gitimages/pass_creator_visual_settings.png)

![Pass Detail Page](.gitimages/pass_detail_page.png)

![Pass History](.gitimages/pass_history.png)



# Some usable textures

```lua
local usableTileTextures = {
    "prog_mp_season",
    "prog_mp_halloween_season",
    "prog_mp_b_season",
    "prog_mp_04_quickdraw",
    "prog_mp_03_quickdraw",
    "prog_mp_02_quickdraw",
    "prog_mp_02_halloween",
    "prog_mp_01_quickdraw",
}
local usableSeasonInfoScreen = {
    headers = {
        "halloween_pass_pop_up",
        "vip_pass_pop_up",
    },
    gradients = {
        "halloween_pass_pop_up",
        "vip_pass_pop_up",
    },
    backgrounds = {
        {
            dict = "halloween_pass_pop_up",
            textures = {
                "halloween_pass_pop_up_welcome_bg",
                "halloween_pass_pop_up_bg",
                "halloween_pass_pop_up_purchase_confirmation_bg",
            }
        },
        {
            dict = "vip_pass_pop_up_purchase_confirmation_bg",
            textures = {
                "vip_pass_pop_up_purchase_confirmation_bg",
            }
        },
        {
            dict = "vip_pass_pop_up_bg",
            textures = {
                "vip_pass_pop_up_bg",
            }
        },
        {
            dict = "halloween_pass_pop_up_welcome_bg",
            textures = {
                "halloween_pass_pop_up_welcome_bg",
            }
        },
        {
            dict = "halloween_pass_pop_up_bg",
            textures = {
                "halloween_pass_pop_up_bg",
            }
        },
        {
            dict = "vip_pass_pop_up_welcome_bg",
            textures = {
                "vip_pass_pop_up_welcome_bg",
            }
        },
        {
            dict = "halloween_pass_pop_up_purchase_confirmation_bg",
            textures = {
                "halloween_pass_pop_up_purchase_confirmation_bg",
            }
        },
        {
            dict = "vip_pass_d_pop_up_purchase_confirmation_bg",
            textures = {
                "vip_pass_d_pop_up_purchase_confirmation_bg",
            }
        },
        {
            dict = "vip_pass_b_pop_up_welcome_bg",
            textures = {
                "vip_pass_b_pop_up_welcome_bg",
            }
        },
        {
            dict = "vip_pass_c_pop_up_welcome_bg",
            textures = {
                "vip_pass_c_pop_up_welcome_bg",
            }
        },
        {
            dict = "vip_pass_c_pop_up_bg",
            textures = {
                "vip_pass_c_pop_up_bg",
            }
        },
        {
            dict = "vip_pass_d_pop_up_welcome_bg",
            textures = {
                "vip_pass_d_pop_up_welcome_bg",
            }
        },
        {
            dict = "vip_pass_b_pop_up_bg",
            textures = {
                "vip_pass_b_pop_up_bg",
            }
        },
        {
            dict = "vip_pass_d_pop_up_bg",
            textures = {
                "vip_pass_d_pop_up_bg",
            }
        },
        {
            dict = "vip_pass_b_pop_up_purchase_confirmation_bg",
            textures = {
                "vip_pass_b_pop_up_purchase_confirmation_bg",
            }
        },
        {
            dict = "vip_pass_c_pop_up_purchase_confirmation_bg",
            textures = {
                "vip_pass_c_pop_up_purchase_confirmation_bg",
            }
        }
    }
}
local backgorundImages ={
    "walk_style_greenhorn",
    "upgrade_photo_pose_two_chairs",
    "upgrade_photo_pose_pistols_v_formation",
    "upgrade_photo_backdrop_travel_beach",
    "upgrade_photo_backdrop_role_moonshiner",
    "upgrade_photo_backdrop_interior_theatre",
    "upgrade_photo_backdrop_countryside_snowfield",
    "upgrade_moonshiner_bar_photo_13",
    "upgrade_moonshiner_bar_photo_09",
    "upgrade_moonshiner_bar_photo_07",
    "upgrade_moonshiner_bar_photo_05",
    "upgrade_camp_follower_outfit_generic_09",
    "upgrade_camp_follower_outfit_generic_08",
    "upgrade_camp_follower_outfit_generic_07",
    "upgrade_camp_flag_state_anchor_blue_00",
    "upgrade_camp_flag_brand_pmgin_default_00",
    "upgrade_camp_flag_brand_obeyes_default_00",
    "upgrade_camp_flag_brand_lucifers_default_00",
    "upgrade_camp_flag_brand_lcola_default_00",
    "upgrade_camp_flag_brand_jjacks_default_00",
    "upgrade_camp_flag_animl_catfish_default_00",
    "upgrade_camp_dog_husky_003",
    "kit_emote_reaction_surrender_1",
    "kit_emote_dance_wild_a_1",
    "kit_emote_dance_old_a_1",
    "kit_emote_dance_graceful_a_1",
    "kit_emote_action_newthreads_1",
    "kit_emote_action_coin_flip_1",
    "horse_equipment_mask_new_005_tint_001",
    "horse_equipment_mask_new_004_tint_001",
    "horse_equipment_mask_new_003_tint_001",
    "horse_equipment_mask_new_000_tint_007",
    "clothing_style_m_outlaw_vest_000",
    "clothing_style_f_outlaw_vest_000",
    "clothing_outfit_item_m_season_s02_002",
    "clothing_outfit_item_m_season_s02_001",
    "clothing_outfit_item_m_outlaw_001",
    "clothing_outfit_item_f_season_s02_002",
    "clothing_outfit_item_f_season_s02_001",
    "clothing_outfit_item_f_outlaw_001",
    "clothing_item_m_season_eyewear_001_tint_001",
    "clothing_item_m_season_buckle_001_var_004",
    "clothing_item_m_season_buckle_001_var_003",
    "clothing_item_m_season_buckle_001_var_002",
    "clothing_item_m_season_buckle_001_var_001",
    "clothing_item_m_poncho_007_tint_001",
    "clothing_item_m_outlaw_pants_000",
    "clothing_item_m_outlaw_neckwear_000",
    "clothing_item_m_outlaw_hat_000",
    "clothing_item_m_outlaw_coat_000",
    "clothing_item_m_outlaw_boots_000",
    "clothing_item_m_gauntlets_001_tint_001",
    "clothing_item_m_frontier_shirt_000",
    "clothing_item_m_frontier_pants_000",
    "clothing_item_m_frontier_neckwear_000",
    "clothing_item_m_frontier_hat_000",
    "clothing_item_m_frontier_coat_000",
    "clothing_item_m_frontier_boots_000",
    "clothing_item_m_eyewear_002_tint_001",
    "clothing_item_f_season_eyewear_001_tint_001",
    "clothing_item_f_season_buckle_001_var_004",
    "clothing_item_f_season_buckle_001_var_003",
    "clothing_item_f_season_buckle_001_var_002",
    "clothing_item_f_season_buckle_001_var_001",
    "clothing_item_f_poncho_007_tint_001",
    "clothing_item_f_outlaw_pants_000",
    "clothing_item_f_outlaw_neckwear_000",
    "clothing_item_f_outlaw_hat_000",
    "clothing_item_f_outlaw_coat_000",
    "clothing_item_f_outlaw_boots_000",
    "clothing_item_f_gauntlets_001_tint_001",
    "clothing_item_f_frontier_shirt_000",
    "clothing_item_f_frontier_pants_000",
    "clothing_item_f_frontier_neckwear_000",
    "clothing_item_f_frontier_hat_000",
    "clothing_item_f_frontier_coat_000",
    "clothing_item_f_frontier_boots_000",
    "clothing_item_f_eyewear_002_tint_001",
}

```

# More textures
[Item Backgrounds](texturesforui/item-bg)

[Popup Backgrounds](texturesforui/season_pass_popup_bg)