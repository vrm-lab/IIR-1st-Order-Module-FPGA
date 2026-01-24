# ============================================================
# create_project.tcl
# Minimal Vivado project creation script
# Board: Kria KV260
# ============================================================

create_project IIR1 ./IIR1 -part xck26-sfvc784-2LV-c
set_property board_part xilinx.com:kv260_som:part0:1.4 [current_project]

set_property target_language Verilog [current_project]

# Optional: keep project clean
set_property ip_repo_paths ./ip_repo [current_project]

puts "Project created."
puts "Next steps:"
puts "  - Add RTL sources from rtl/"
puts "  - Source bd.tcl to recreate block design"
