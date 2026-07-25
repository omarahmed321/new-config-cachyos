#!/usr/bin/env python3
import os
import sys
import subprocess
import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib

CONFIG_PATH = os.path.expanduser('~/.config/hypr/nightlight.conf')
SCRIPT_PATH = os.path.expanduser('~/.local/share/bin/nightlight-start.sh')

class NightlightConfigApp(Gtk.Window):
    def __init__(self):
        super().__init__(title="Night Light Configuration - إعدادات الإضاءة الليلية")
        self.set_default_size(480, 320)
        self.set_border_width(20)
        self.set_position(Gtk.WindowPosition.CENTER)

        # Default values
        self.temperature = 3500
        self.gamma = 100
        self.enabled = True

        self.load_config()

        # Layout
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        self.add(vbox)

        # Title Label
        title_label = Gtk.Label()
        title_label.set_markup("<span size='large' weight='bold'>🌙 Night Light Settings / الإضاءة الليلية</span>")
        vbox.pack_start(title_label, False, False, 0)

        # Enable Switch
        switch_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        switch_label = Gtk.Label(label="Enable Night Light / تفعيل الإضاءة الليلية:")
        self.switch = Gtk.Switch()
        self.switch.set_active(self.enabled)
        switch_box.pack_start(switch_label, True, True, 0)
        switch_box.pack_end(self.switch, False, False, 0)
        vbox.pack_start(switch_box, False, False, 0)

        # Temperature Scale
        temp_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        temp_lbl = Gtk.Label(label="Color Temperature / درجة حرارة اللون (Warm 1000K - Cool 6500K):")
        temp_lbl.set_xalign(0)
        self.temp_scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 1000, 6500, 100)
        self.temp_scale.set_value(self.temperature)
        temp_box.pack_start(temp_lbl, False, False, 0)
        temp_box.pack_start(self.temp_scale, False, False, 0)
        vbox.pack_start(temp_box, False, False, 0)

        # Gamma / Brightness Scale
        gamma_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        gamma_lbl = Gtk.Label(label="Brightness Level / مستوى السطوع (%):")
        gamma_lbl.set_xalign(0)
        self.gamma_scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 10, 100, 5)
        self.gamma_scale.set_value(self.gamma)
        gamma_box.pack_start(gamma_lbl, False, False, 0)
        gamma_box.pack_start(self.gamma_scale, False, False, 0)
        vbox.pack_start(gamma_box, False, False, 0)

        # Save Button
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.apply_btn = Gtk.Button(label="Apply & Save / تطبيق وحفظ")
        self.apply_btn.get_style_context().add_class("suggested-action")
        self.apply_btn.connect("clicked", self.on_apply_clicked)
        btn_box.pack_end(self.apply_btn, True, True, 0)
        vbox.pack_start(btn_box, False, False, 10)

        # Status Bar
        self.status_label = Gtk.Label(label="")
        vbox.pack_start(self.status_label, False, False, 0)

    def load_config(self):
        if os.path.exists(CONFIG_PATH):
            try:
                with open(CONFIG_PATH, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if '=' in line and not line.startswith('#'):
                            k, v = line.split('=', 1)
                            k, v = k.strip(), v.strip()
                            if k == 'temperature':
                                self.temperature = int(v)
                            elif k == 'gamma':
                                self.gamma = int(v)
                            elif k == 'enabled':
                                self.enabled = (v.lower() == 'true')
            except Exception as e:
                print(f"Error reading config: {e}")

    def on_apply_clicked(self, widget):
        temp = int(self.temp_scale.get_value())
        gamma = int(self.gamma_scale.get_value())
        enabled = self.switch.get_active()

        os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
        try:
            with open(CONFIG_PATH, 'w') as f:
                f.write(f"temperature={temp}\n")
                f.write(f"gamma={gamma}\n")
                f.write(f"enabled={'true' if enabled else 'false'}\n")
            
            # Apply changes live
            if os.path.exists(SCRIPT_PATH):
                subprocess.Popen(['bash', SCRIPT_PATH])
            elif enabled:
                gamma_float = f"{gamma / 100.0:.2f}"
                subprocess.Popen(['pkill', '-x', 'hyprsunset'])
                subprocess.Popen(['hyprsunset', '-t', str(temp), '-g', gamma_float])
            else:
                subprocess.Popen(['pkill', '-x', 'hyprsunset'])

            self.status_label.set_markup("<span foreground='green'>✓ Settings saved &amp; applied successfully!</span>")
        except Exception as e:
            self.status_label.set_markup(f"<span foreground='red'>❌ Error: {e}</span>")

if __name__ == '__main__':
    app = NightlightConfigApp()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
