if { [info exists synopsys_program_name ] && ($synopsys_program_name == "icc2_shell") } {
    puts " Creating ICC2 MCMM "
    create_mode func
    create_corner slow
    create_scenario -mode func -corner slow -name func_slow
    current_scenario func_slow
    set_operating_conditions ss0p75v125c
    read_parasitic_tech -tlup $tlu_dir/saed32nm_1p9m_Cmax.tluplus -layermap $tlu_dir/saed32nm_tf_itf_tluplus.map -name Cmax
    read_parasitic_tech -tlup $tlu_dir/saed32nm_1p9m_Cmin.tluplus -layermap $tlu_dir/saed32nm_tf_itf_tluplus.map -name Cmin
    set_parasitic_parameters -early_spec Cmax -early_temperature 125
    set_parasitic_parameters -late_spec Cmax -late_temperature 125
    #set_parasitic_parameters -early_spec 1p9m_Cmax -early_temperature 125 -corner default
    #set_parasitic_parameters -late_spec 1p9m_Cmax -late_temperature 125 -corner default

    #set_scenario_status  default -active false
    set_scenario_status func_slow -active true -hold true -setup true
}
#changing the time period of the clocks to constrain more
set wclk_period 0.8
set rclk_period 0.8
set wclk2x_period [ expr $wclk_period / 2 ]

create_clock -name "wclk" -period $wclk_period  wclk 


create_clock -name "rclk" -period $rclk_period rclk 

#Add the new clock.  Make it 1/2 the wclk period since it is called wclk2x
create_clock -name "wclk2x" -period $wclk2x_period wclk2x 

#false paths to prevent the tool from timing paths between these clocks
set_false_path -from [get_clocks wclk] -to [get_clocks rclk]
set_false_path -from [get_clocks rclk] -to [ get_clocks wclk]
set_false_path -from [get_clocks rclk] -to [ get_clocks wclk2x]
set_false_path -from [get_clocks wclk2x] -to [ get_clocks rclk]

##adding input delay to constraint in2reg/in2out paths
set_input_delay -max -clock wclk -0.4 [get_ports "winc"]
set_input_delay -max -clock rclk -0.5 [get_ports "rinc"]
set_input_delay -max -clock wclk2x -0.5 [get_ports "wdata_in*"]

set_input_delay -min -clock wclk -0.4 [get_ports "winc"]
set_input_delay -min -clock rclk -0.5 [get_ports "rinc"]
set_input_delay -min -clock wclk2x -0.5 [get_ports "wdata_in*"]

#adding driving cell to let the tool know what is driving the input of our design
set_driving_cell -lib_cell  NBUFFX2_RVT [remove_from_collection [get_ports -filter "direction==in"] [get_ports "rclk wclk wclk2x"]]

##adding output delay to constraint in2out/reg2out paths
set_output_delay -max -clock wclk -1.2 [get_ports "wfull"]
set_output_delay -max -clock rclk -1.2  [get_ports "rempty"] 
set_output_delay -max -clock wclk2x -1.0 [get_ports "rdata*"]

set_output_delay -min -clock wclk -1.2 [get_ports "wfull"]
set_output_delay -min -clock rclk -1.2  [get_ports "rempty"] 
set_output_delay -min -clock wclk2x -1.0 [get_ports "rdata*"]

#adding load to let the tool know what the load will be for our design
set_load 0.02 [get_ports -filter "direction==out"]

#clock latency transition and uncertainity are approximate constraints to give before doing PNR
#we give them as a percentage of clock
set_clock_latency 0.4 [get_ports "rclk wclk wclk2x"]
set_clock_transition 0.2 [get_clocks "rclk wclk wclk2x"]
set_clock_uncertainty -setup 0.04 [get_ports "rclk wclk wclk2x"]
set_input_transition -min 0.2 [get_ports "rclk wclk wclk2x"]
set_input_transition -max 0.2 [get_ports "rclk wclk wclk2x"]
set_clock_uncertainty -hold 0.04 [get_ports "rclk wclk wclk2x"]


# Add input/output delays in relation to related clocks
# Can tell the related clock by doing report_timing -group INPUTS  or -group OUTPUTS after using group_path
# External delay should be some percentage of clock period.
# Tune/relax if violating; most concerned about internal paths.

# I like set_driving_cell to a std cell from the library.  set_drive works to.

# grouping oaths make our debugging easy 
group_path -name INTERNAL -from [all_clocks] -to [all_clocks ]
group_path -name INPUTS -from [ get_ports -filter "direction==in&&full_name!~*clk*" ]
group_path -name OUTPUTS -to [ get_ports -filter "direction==out" ]
