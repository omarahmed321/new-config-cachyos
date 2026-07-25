#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib

MONITORS_CONF = os.path.expanduser('~/.config/hypr/monitors.conf')

class MonitorAlignmentApp(Gtk.Window):
    def __init__(self):
        super().__init__(title="Dual Monitor Alignment - محاذاة الشاشات المتعددة")
        self.set_default_size(650, 480)
        self.set_border_width(20)
        self.set_position(Gtk.WindowPosition.CENTER)

        self.monitors = self.load_monitors()

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        self.add(vbox)

        # Title
        title_label = Gtk.Label()
        title_label.set_markup("<span size='large' weight='bold'>🖥️ Multi-Monitor Alignment / محاذاة الشاشات</span>")
        vbox.pack_start(title_label, False, False, 0)

        subtitle = Gtk.Label(label="Adjust X/Y offsets to smooth cursor transitions between monitors:")
        vbox.pack_start(subtitle, False, False, 0)

        # Monitor 1 Controls
        grid = Gtk.Grid()
        grid.set_column_spacing(15)
        grid.set_row_spacing(10)
        vbox.pack_start(grid, False, False, 0)

        # Monitor 1 (Main)
        lbl_m1 = Gtk.Label(label="<b>Monitor 1 (Main):</b>", use_markup=True)
        lbl_m1.set_xalign(0)
        grid.attach(lbl_m1, 0, 0, 1, 1)

        self.combo_m1 = Gtk.ComboBoxText()
        grid.attach(self.combo_m1, 1, 0, 2, 1)

        lbl_m1_pos = Gtk.Label(label="Position (X, Y): 0x0 (Primary Origin)")
        lbl_m1_pos.set_xalign(0)
        grid.attach(lbl_m1_pos, 0, 1, 3, 1)

        # Monitor 2 (Secondary)
        lbl_m2 = Gtk.Label(label="<b>Monitor 2 (Secondary):</b>", use_markup=True)
        lbl_m2.set_xalign(0)
        grid.attach(lbl_m2, 0, 2, 1, 1)

        self.combo_m2 = Gtk.ComboBoxText()
        grid.attach(self.combo_m2, 1, 2, 2, 1)

        # Spinners for Monitor 2 Position
        lbl_x = Gtk.Label(label="X Offset (px):")
        self.spin_x = Gtk.SpinButton.new_with_range(-3840, 7680, 10)
        self.spin_x.set_value(2560)
        grid.attach(lbl_x, 0, 3, 1, 1)
        grid.attach(self.spin_x, 1, 3, 1, 1)

        lbl_y = Gtk.Label(label="Y Offset (px):")
        self.spin_y = Gtk.SpinButton.new_with_range(-2160, 4320, 10)
        self.spin_y.set_value(0)
        grid.attach(lbl_y, 0, 4, 1, 1)
        grid.attach(self.spin_y, 1, 4, 1, 1)

        # Quick Preset Buttons
        preset_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        btn_right = Gtk.Button(label="Side by Side (Right)")
        btn_right.connect("clicked", lambda w: self.apply_preset('right'))
        btn_left = Gtk.Button(label="Side by Side (Left)")
        btn_left.connect("clicked", lambda w: self.apply_preset('left'))
        btn_top = Gtk.Button(label="Stacked Above")
        btn_top.connect("clicked", lambda w: self.apply_preset('top'))

        preset_box.pack_start(btn_right, True, True, 0)
        preset_box.pack_start(btn_left, True, True, 0)
        preset_box.pack_start(btn_top, True, True, 0)
        vbox.pack_start(preset_box, False, False, 0)

        # Fill ComboBoxes
        mon_names = list(self.monitors.keys())
        if len(mon_names) < 2:
            mon_names.append('HDMI-A-1')

        for name in mon_names:
            self.combo_m1.append_text(name)
            self.combo_m2.append_text(name)

        self.combo_m1.set_active(0)
        self.combo_m2.set_active(1 if len(mon_names) > 1 else 0)

        # Save Button
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.apply_btn = Gtk.Button(label="Apply & Save Alignment / تطبيق وحفظ المحاذاة")
        self.apply_btn.get_style_context().add_class("suggested-action")
        self.apply_btn.connect("clicked", self.on_apply_clicked)
        btn_box.pack_end(self.apply_btn, True, True, 0)
        vbox.pack_start(btn_box, False, False, 10)

        self.status_label = Gtk.Label(label="")
        vbox.pack_start(self.status_label, False, False, 0)

    def load_monitors(self):
        monitors = {}
        try:
            res = subprocess.check_output(['hyprctl', 'monitors', '-j'], text=True)
            data = json.loads(res)
            for m in data:
                name = m.get('name')
                res_str = f"{m.get('width')}x{m.get('height')}@{int(m.get('refreshRate', 60))}"
                scale = f"{float(m.get('scale', 1.0)):.2f}".rstrip('0').rstrip('.')
                x = m.get('x', 0)
                y = m.get('y', 0)
                monitors[name] = {'res': res_str, 'scale': scale, 'x': x, 'y': y}
        except Exception:
            pass

        if not monitors:
            monitors['eDP-1'] = {'res': '2560x1600@165', 'scale': '1.67', 'x': 0, 'y': 0}
            monitors['HDMI-A-1'] = {'res': '1920x1080@60', 'scale': '1.0', 'x': 2560, 'y': 0}
        return monitors

    def apply_preset(self, mode):
        m1_name = self.combo_m1.get_active_text() or 'eDP-1'
        m1_res = self.monitors.get(m1_name, {}).get('res', '2560x1600@165')
        w, h = 2560, 1600
        if 'x' in m1_res:
            try:
                w = int(m1_res.split('x')[0])
                h = int(m1_res.split('x')[1].split('@')[0])
            except Exception:
                pass

        if mode == 'right':
            self.spin_x.set_value(w)
            self.spin_y.set_value(0)
        elif mode == 'left':
            self.spin_x.set_value(-1920)
            self.spin_y.set_value(0)
        elif mode == 'top':
            self.spin_x.set_value(0)
            self.spin_y.set_value(-1080)

    def on_apply_clicked(self, widget):
        m1 = self.combo_m1.get_active_text() or 'eDP-1'
        m2 = self.combo_m2.get_active_text() or 'HDMI-A-1'
        x2 = int(self.spin_x.get_value())
        y2 = int(self.spin_y.get_value())

        m1_info = self.monitors.get(m1, {'res': '2560x1600@165', 'scale': '1.67'})
        m2_info = self.monitors.get(m2, {'res': '1920x1080@60', 'scale': '1.0'})

        os.makedirs(os.path.dirname(MONITORS_CONF), exist_ok=True)
        try:
            with open(MONITORS_CONF, 'w') as f:
                f.write(f"# Monitor alignment generated by monitor-alignment.py\n")
                f.write(f"monitor = {m1},{m1_info['res']},0x0,{m1_info['scale']}\n")
                if m1 != m2:
                    f.write(f"monitor = {m2},{m2_info['res']},{x2}x{y2},{m2_info['scale']}\n")
                f.write(f"\nworkspace = 1, monitor:{m1}, default:true\n")
                for i in range(2, 6):
                    f.write(f"workspace = {i}, monitor:{m1}\n")
                for i in range(6, 11):
                    f.write(f"workspace = {i}, monitor:{m2 if m1 != m2 else m1}\n")

            # Apply via hyprctl
            subprocess.Popen(['hyprctl', 'keyword', 'monitor', f"{m1},{m1_info['res']},0x0,{m1_info['scale']}"])
            if m1 != m2:
                subprocess.Popen(['hyprctl', 'keyword', 'monitor', f"{m2},{m2_info['res']},{x2}x{y2},{m2_info['scale']}"])

            self.status_label.set_markup("<span foreground='green'>✓ Monitor alignment saved successfully!</span>")
        except Exception as e:
            self.status_label.set_markup(f"<span foreground='red'>❌ Error: {e}</span>")

if __name__ == '__main__':
    app = MonitorAlignmentApp()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
