#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib

MONITORS_CONF = os.path.expanduser('~/.config/hypr/monitors.conf')
USERPREFS_CONF = os.path.expanduser('~/.config/hypr/userprefs.conf')

class DisplayConfigApp(Gtk.Window):
    def __init__(self):
        super().__init__(title="Display & Input Settings - إعدادات الشاشة والماوس")
        self.set_default_size(520, 440)
        self.set_border_width(20)
        self.set_position(Gtk.WindowPosition.CENTER)

        self.monitors = self.detect_monitors()

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        self.add(vbox)

        # Title
        title_label = Gtk.Label()
        title_label.set_markup("<span size='large' weight='bold'>🖥️ Display &amp; Mouse Settings / الشاشة والماوس</span>")
        vbox.pack_start(title_label, False, False, 0)

        # Monitor Selection Dropdown
        mon_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        mon_label = Gtk.Label(label="Select Monitor / اختر الشاشة:")
        self.combo_mon = Gtk.ComboBoxText()
        for name in self.monitors.keys():
            self.combo_mon.append_text(name)
        if self.monitors:
            self.combo_mon.set_active(0)
        self.combo_mon.connect("changed", self.on_monitor_changed)
        mon_box.pack_start(mon_label, False, False, 0)
        mon_box.pack_start(self.combo_mon, True, True, 0)
        vbox.pack_start(mon_box, False, False, 0)

        # Resolution Entry
        res_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        res_label = Gtk.Label(label="Resolution / الدقة (e.g. 2560x1600):")
        self.res_entry = Gtk.Entry()
        res_box.pack_start(res_label, True, True, 0)
        res_box.pack_end(self.res_entry, False, False, 0)
        vbox.pack_start(res_box, False, False, 0)

        # Refresh Rate Entry
        rate_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        rate_label = Gtk.Label(label="Refresh Rate / معدل التحديث (Hz):")
        self.rate_entry = Gtk.Entry()
        rate_box.pack_start(rate_label, True, True, 0)
        rate_box.pack_end(self.rate_entry, False, False, 0)
        vbox.pack_start(rate_box, False, False, 0)

        # Scale Entry
        scale_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        scale_label = Gtk.Label(label="Display Scale / مقياس العرض (e.g. 1.0, 1.25, 1.67):")
        self.scale_entry = Gtk.Entry()
        scale_box.pack_start(scale_label, True, True, 0)
        scale_box.pack_end(self.scale_entry, False, False, 0)
        vbox.pack_start(scale_box, False, False, 0)

        # Separator
        vbox.pack_start(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL), False, False, 5)

        # Mouse Sensitivity Scale
        sens_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        sens_label = Gtk.Label(label="Mouse Sensitivity / حساسية الماوس (-1.0 to 1.0):")
        sens_label.set_xalign(0)
        self.sens_scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, -1.0, 1.0, 0.05)
        self.sens_scale.set_value(0.0)
        sens_box.pack_start(sens_label, False, False, 0)
        sens_box.pack_start(self.sens_scale, False, False, 0)
        vbox.pack_start(sens_box, False, False, 0)

        self.populate_current_mon_data()

        # Save Button
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.apply_btn = Gtk.Button(label="Apply & Save / تطبيق وحفظ")
        self.apply_btn.get_style_context().add_class("suggested-action")
        self.apply_btn.connect("clicked", self.on_apply_clicked)
        btn_box.pack_end(self.apply_btn, True, True, 0)
        vbox.pack_start(btn_box, False, False, 5)

        self.status_label = Gtk.Label(label="")
        vbox.pack_start(self.status_label, False, False, 0)

    def detect_monitors(self):
        monitors = {}
        # Try hyprctl JSON
        try:
            res = subprocess.check_output(['hyprctl', 'monitors', '-j'], text=True)
            data = json.loads(res)
            for m in data:
                name = m.get('name', 'eDP-1')
                width = m.get('width', 1920)
                height = m.get('height', 1080)
                rate = int(m.get('refreshRate', 60))
                scale = float(m.get('scale', 1.0))
                x = m.get('x', 0)
                y = m.get('y', 0)
                monitors[name] = {
                    'res': f"{width}x{height}",
                    'rate': str(rate),
                    'scale': f"{scale:.2f}".rstrip('0').rstrip('.'),
                    'pos': f"{x}x{y}"
                }
        except Exception:
            pass

        # Fallback to parsing monitors.conf if hyprctl isn't available
        if not monitors and os.path.exists(MONITORS_CONF):
            with open(MONITORS_CONF, 'r') as f:
                for line in f:
                    if line.strip().startswith('monitor'):
                        parts = line.split('=', 1)[1].split(',')
                        if len(parts) >= 4:
                            name = parts[0].strip()
                            res_rate = parts[1].strip()
                            pos = parts[2].strip()
                            scale = parts[3].strip()
                            res, rate = res_rate.split('@') if '@' in res_rate else (res_rate, "60")
                            monitors[name] = {'res': res, 'rate': rate, 'scale': scale, 'pos': pos}

        if not monitors:
            monitors['eDP-1'] = {'res': '2560x1600', 'rate': '165', 'scale': '1.67', 'pos': '0x0'}
        return monitors

    def on_monitor_changed(self, combo):
        self.populate_current_mon_data()

    def populate_current_mon_data(self):
        name = self.combo_mon.get_active_text()
        if name and name in self.monitors:
            m = self.monitors[name]
            self.res_entry.set_text(m.get('res', '1920x1080'))
            self.rate_entry.set_text(m.get('rate', '60'))
            self.scale_entry.set_text(m.get('scale', '1.0'))

    def on_apply_clicked(self, widget):
        mon_name = self.combo_mon.get_active_text() or 'eDP-1'
        res = self.res_entry.get_text().strip()
        rate = self.rate_entry.get_text().strip()
        scale = self.scale_entry.get_text().strip()
        sens = self.sens_scale.get_value()

        pos = self.monitors.get(mon_name, {}).get('pos', '0x0')

        # Write to monitors.conf
        os.makedirs(os.path.dirname(MONITORS_CONF), exist_ok=True)
        try:
            with open(MONITORS_CONF, 'w') as f:
                f.write(f"monitor = {mon_name},{res}@{rate},{pos},{scale}\n\n")
                f.write(f"workspace = 1, monitor:{mon_name}, default:true\n")
                for i in range(2, 11):
                    f.write(f"workspace = {i}, monitor:{mon_name}\n")

            # Apply via hyprctl
            subprocess.Popen(['hyprctl', 'keyword', 'monitor', f"{mon_name},{res}@{rate},{pos},{scale}"])
            subprocess.Popen(['hyprctl', 'keyword', 'input:sensitivity', str(sens)])

            self.status_label.set_markup("<span foreground='green'>✓ Display &amp; Mouse settings saved!</span>")
        except Exception as e:
            self.status_label.set_markup(f"<span foreground='red'>❌ Error: {e}</span>")

if __name__ == '__main__':
    app = DisplayConfigApp()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
