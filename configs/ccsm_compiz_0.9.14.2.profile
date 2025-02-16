[switcher]
s0_next_all_key = Disabled
s0_prev_all_key = Disabled
s0_speed = 4.500000
s0_timestep = 0.100000
s0_size_multiplier = 2.000000
s0_brightness = 100
s0_opacity = 100
s0_zoom = 0.000000
s0_auto_rotate = true
s0_background_color = #000000ff

[ezoom]
s0_zoom_in_button = <Super>Button4
s0_zoom_out_button = <Super>Button5
s0_zoom_box_outline_color = #2f2f4f9f
s0_zoom_box_fill_color = #2f2f2f4f
s0_zoom_mode = 1
s0_speed = 30.000000

[wobbly]
s0_snap_key = Disabled
s0_friction = 8.000000
s0_spring_k = 10.000000
s0_map_window_match = 
s0_move_window_match = 

[composite]
s0_unredirect_match = (any) & !(class=mpv) & !(class=Vlc) & !(class=google-chrome) & !(class=chromium-browser-chromium)

[animation]
s0_open_effects = animation:Zoom;animation:Fade;animation:Fade;
s0_open_durations = 120;80;80;
s0_open_matches = (type=Normal | Unknown) & !(type=Normal & override_redirect=1);((type=Menu | PopupMenu | DropdownMenu | Combo | Dialog | ModalDialog | Normal) & !(class=\\.exe$));(type=Tooltip | Notification | Utility) & !(name=compiz) & !(title=notify-osd);
s0_close_effects = animation:Glide 2;animation:Fade;animation:Fade;
s0_close_matches = (type=Normal | Unknown) & !(type=Normal & override_redirect=1);((type=Menu | PopupMenu | DropdownMenu | Combo | Dialog | ModalDialog | Normal) & !(class=\\.exe$));(type=Tooltip | Notification | Utility) & !(name=compiz) & !(title=notify-osd);
s0_minimize_effects = animation:Dream;
s0_minimize_durations = 120;
s0_unminimize_effects = animation:Dream;
s0_unminimize_durations = 120;
s0_focus_effects = animation:None;
s0_dream_zoom_to_taskbar = false
s0_zoom_from_center = 3

[resizeinfo]
s0_fade_time = 100
s0_resizeinfo_font_bold = false
s0_resizeinfo_font_size = 14
s0_gradient_1 = #ffffff80
s0_gradient_2 = #ffffff80
s0_gradient_3 = #ffffff80
s0_outline_color = #000000ff

[expo]
s0_expo_key = <Alt><Super>space
s0_next_vp_button = Disabled
s0_prev_vp_button = Disabled
s0_zoom_time = 0.150000
s0_deform = 2
s0_curve = 0.750000
s0_x_offset = 0
s0_y_offset = 0
s0_distance = 0.060000
s0_vp_distance = 0.000000
s0_aspect_ratio = 0.750000
s0_vp_brightness = 100.000000

[grid]
s0_put_center_key = <Alt><Super>o
s0_put_left_key = <Alt><Super>h
s0_put_right_key = <Alt><Super>l
s0_put_top_key = <Alt><Super>k
s0_put_bottom_key = <Alt><Super>j
s0_put_topleft_key = Disabled
s0_put_topright_key = Disabled
s0_put_bottomleft_key = Disabled
s0_put_bottomright_key = Disabled
s0_put_maximize_key = Disabled
s0_put_restore_key = <Alt><Super>n
s0_left_maximize = Disabled
s0_right_maximize = Disabled
s0_top_left_corner_action = 7
s0_top_edge_action = 8
s0_top_right_corner_action = 9
s0_bottom_left_corner_action = 1
s0_bottom_edge_action = 2
s0_bottom_right_corner_action = 3
s0_snapback_windows = false
s0_cycle_sizes = true
s0_snapoff_threshold = 0
s0_animation_duration = 100

[opengl]
s0_texture_filter = 2

[winrules]
s0_no_argb_match = !(class=Xfce4-terminal) & !(class=Xfce4-panel)

[resize]
s0_initiate_button = <Alt>Button3
s0_initiate_key = <Alt><Super>Return
s0_mode = 2
s0_maximize_vertically = false
s0_border_color = #d02060ff
s0_fill_color = #d0206056

[scaleaddon]
s0_close_button = Disabled
s0_zoom_button = Disabled
s0_window_title = 2
s0_title_size = 32
s0_border_size = 10
s0_highlight_color = #ffffff1a
s0_layout_mode = 1
s0_natural_precision = 10.000000
s0_exit_after_pull = true

[core]
s0_active_plugins = core;composite;crashhandler;opengl;compiztoolbox;decor;firepaint;grid;imgjpeg;imgpng;imgsvg;mousepoll;move;neg;place;put;regex;resize;resizeinfo;text;winrules;wobbly;animation;annotate;cube;expo;ezoom;rotate;scale;scaleaddon;switcher;
s0_audible_bell = false
s0_outputs = 3840x2160+0+0;
s0_focus_prevention_level = 0
s0_close_window_key = Disabled
s0_raise_window_button = Disabled
s0_lower_window_button = Disabled
s0_minimize_window_key = Disabled
s0_maximize_window_key = Disabled
s0_unmaximize_or_minimize_window_key = Disabled
s0_window_menu_button = Disabled
s0_toggle_window_maximized_key = Disabled
s0_toggle_window_shaded_key = Disabled
s0_hsize = 2

[decor]
s0_active_shadow_radius = 18.000000
s0_active_shadow_opacity = 1.500000
s0_active_shadow_color = #000000ff
s0_active_shadow_x_offset = 0
s0_active_shadow_y_offset = 0
s0_inactive_shadow_radius = 18.000000
s0_inactive_shadow_opacity = 1.500000
s0_inactive_shadow_color = #000000ff
s0_inactive_shadow_x_offset = 0
s0_inactive_shadow_y_offset = 0
s0_decoration_match = (!any) & !(class=org.remmina.Remmina)
s0_shadow_match = (any) & !(class=org.remmina.Remmina)

[move]
s0_initiate_key = <Super>Return
s0_opacity = 90
s0_key_move_inc = 50
s0_snapoff_semimaximized = false
s0_snapback_semimaximized = false

[firepaint]
s0_initiate_button = <Control><Alt><Super>Button1
s0_clear_key = Disabled
s0_clear_button = <Control><Alt><Super>Button3
s0_bg_brightness = 100.000000
s0_num_particles = 2500
s0_fire_slowdown = 5.000000
s0_fire_life = 0.800000
s0_fire_color = #00ffff38

[put]
s0_put_center_key = <Super>n
s0_put_left_key = <Super>h
s0_put_right_key = <Super>l
s0_put_top_key = <Super>k
s0_put_bottom_key = <Super>j
s0_put_topleft_key = Disabled
s0_put_topright_key = Disabled
s0_put_bottomleft_key = Disabled
s0_put_bottomright_key = Disabled
s0_put_restore_key = Disabled
s0_put_pointer_key = Disabled
s0_pad_left = 10
s0_pad_right = 10
s0_pad_top = 10
s0_pad_bottom = 10
s0_avoid_offscreen = true
s0_speed = 12.500000
s0_timestep = 0.100000

[neg]
s0_window_toggle_key = <Super>f
s0_screen_toggle_key = Disabled

[cube]
s0_unfold_key = Disabled

[annotate]
s0_initiate_line_button = Disabled
s0_initiate_rectangle_button = Disabled
s0_initiate_ellipse_button = Disabled
s0_erase_button = Disabled
s0_clear_button = <Alt><Super>Button3
s0_clear_key = Disabled
s0_stroke_color = #ffa348ff
s0_stroke_width = 5.000000

[rotate]
s0_edge_flip_window = false
s0_edge_flip_dnd = false
s0_flip_time = 175
s0_speed = 4.000000
s0_timestep = 0.100000
s0_initiate_button = Disabled
s0_rotate_left_key = Disabled
s0_rotate_right_key = <Super>Tab
s0_rotate_left_window_key = Disabled
s0_rotate_right_window_key = <Shift><Super>Tab
s0_rotate_flip_left_edge = 
s0_rotate_flip_right_edge = 

[scale]
s0_spacing = 0
s0_speed = 8.000000
s0_darken_back = false
s0_opacity = 75
s0_hover_time = 500
s0_dnd_distance = 5
s0_multioutput_mode = 0
s0_initiate_key = <Super>space
s0_initiate_all_key = Disabled

[workarounds]
s0_ooo_menu_fix = false
s0_java_fix = false
s0_java_taskbar_fix = false
s0_aiglx_fragment_fix = false
s0_initial_damage_complete_redraw = false
s0_force_swap_buffers = true
