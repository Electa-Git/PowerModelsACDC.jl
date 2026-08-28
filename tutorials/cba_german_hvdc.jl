### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# ╔═╡ a5eb6d1d-83a7-418d-b76a-c0cf420c6391
begin
	import Pkg
	import DataFrames; const DF = DataFrames
	import CSV
	import JuMP
	import Gurobi
	import HiGHS
	import Feather
	import PowerModels; const PM = PowerModels
	import JSON
	import PowerModelsACDC; const PMACDC = PowerModelsACDC
	import Plots
	import Statistics
end

# ╔═╡ 4db01edf-a679-4abb-81f4-8819f09986e6
begin
	# Edit this path if your local EUGO checkout is elsewhere.
	local_eugo_path = "/Users/hergun/Julia files/EU_grid_operations"

	# Develop local EUGO package. If already developed, this is harmless but can take a few seconds.
	Pkg.develop(path = local_eugo_path)

	using EU_grid_operations
	const EUGO = EU_grid_operations
end

# ╔═╡ 3b078b52-a2c1-4ada-951c-5ab4280e685a
md"""
!!! info "German-network HVDC portfolio CBA with EUGO and PowerModelsACDC"
    This Pluto notebook performs the same tutorial-style workflow as before, with the requested changes:

    - TYNDP version: **2020**
    - climate year: **2007**
    - scenario: **DE**
    - internal branch rating limited to **15 p.u.** due to inconsistent data
    - candidate HVDC links are evaluated **one-by-one** and then **all together**

    The notebook first runs the zonal hourly OPF, then uses the zonal result to prepare the German nodal model and run the nodal AC/DC OPF comparisons.
"""

# ╔═╡ c9442eef-e502-4033-a274-5e93ba1ab06b
md"""
!!! warning "Local EUGO package"
    This notebook assumes you are using a local checkout of `EU_grid_operations`. Edit `local_eugo_path` below if needed.
"""

# ╔═╡ 634fe521-b0ee-4233-9809-fc0df049c4d7
md"""
!!! info "Input parameters"
    The key requested settings are in this cell: `tyndp_version = "2020"`, `climate_year = "2007"`, and `internal_rate_limit_pu = 15.0`.
"""

# ╔═╡ 1d6aaaca-7732-4783-b22e-c7cfd8b6f7fc
begin
	######### DEFINE INPUT PARAMETERS #########
	tyndp_version = "2020"
	fetch_data = true
	number_of_hours = 168
	start_hour = 3320
	scenario = "DE"
	year = "2040"
	climate_year = "2007"

	# Nodal German-grid settings
	zone = "DE00"
	zones_to_keep = ["DE", "DEKF"]
	border_slack = 0.003

	# Candidate HVDC links. Each entry is evaluated separately and then all together.
	candidate_link_names = ["Suedostlink", "Suedlink", "Ultranet"]
	all_links = Dict(name => [] for name in candidate_link_names)
	candidate_cases = vcat(
		[("Only " * name, Dict(name => all_links[name])) for name in candidate_link_names],
		[("All candidate links", deepcopy(all_links))],
	)

	# Requested branch limit: 15 p.u. for non-border internal high-rating lines.
	limit_internal_5000mva_lines = true
	internal_rate_limit_pu = 15.0

	# Angle limits used in the reference script.
	internal_angmin = -pi
	internal_angmax = pi

	# Optional clean-up used in the provided 2020/2007 example.
	apply_manual_grid_cleanup = true

	# Result switches
	save_zonal_results = true
	save_cba_results = true
	make_zonal_flow_plot = false

	# Output directory
	result_dir = joinpath(pkgdir(EUGO), "results", "TYNDP" * tyndp_version)
	isdir(result_dir) || mkpath(result_dir)
end

# ╔═╡ a1aad4c7-de37-4037-89fa-25d0ba7fba2b
md"""
!!! info "Load TYNDP/EUGO data and construct zonal input dictionary"
    This cell loads the TYNDP 2020 / climate-year 2007 data and constructs the zonal PowerModels-style input dictionary.
"""

# ╔═╡ d528ba87-3370-4ebb-8eab-633e2985cd09
begin
	pv, wind_onshore, wind_offshore = EUGO.load_res_data()

	ntcs, nodes, arcs, capacity, demand, gen_types, gen_costs, emission_factor,
		inertia_constants, node_positions = EUGO.get_grid_data(
			tyndp_version,
			scenario,
			year,
			climate_year,
		)

	input_data, nodal_data = EUGO.construct_data_dictionary(
		tyndp_version,
		ntcs,
		arcs,
		capacity,
		nodes,
		demand,
		scenario,
		year,
		climate_year,
		gen_types,
		pv,
		wind_onshore,
		wind_offshore,
		gen_costs,
		emission_factor,
		inertia_constants,
		node_positions,
	)

	# Keep an unchanged copy for cross-border flow and scenario-data processing later.
	input_data_raw = deepcopy(input_data)
end

# ╔═╡ 935a4cc8-3a3f-48a3-90f2-851764726fff
md"""
!!! info "Select optimisation solver and formulation"
    The zonal model uses `NFAPowerModel`. The nodal German-grid CBA uses `DCPPowerModel` by default.
"""

# ╔═╡ d38cb709-1fda-4b63-83a6-7406f5e34ade
begin
	solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer,
    "output_flag" => false,
    "log_to_console" => false,
)
	zonal_model = PM.NFAPowerModel
	nodal_model = PM.DCPPowerModel

	nodal_opf_setting = Dict(
		"output" => Dict("branch_flows" => true),
		"conv_losses_mp" => true,
		"fix_cross_border_flows" => true,
		"objective_components" => ["gen", "demand"],
	)
end

# ╔═╡ 15eb467a-c6e9-4b42-b384-2609362dc600
md"""
!!! info "Auxiliary functions"
    The most important helper is `has_valid_solution`, which prevents post-processing errors when an OPF is infeasible or returns an empty solution.
"""

# ╔═╡ d9d7a968-98cf-480b-9c65-05115368474f
begin
	function selected_hours(start_hour::Int, number_of_hours::Int)
		return collect(start_hour:start_hour + number_of_hours - 1)
	end

	function has_valid_solution(result)
		return result isa Dict && haskey(result, "solution") && result["solution"] isa Dict && !isempty(result["solution"])
	end

	function safe_objective(result)
		return has_valid_solution(result) ? get(result, "objective", 0.0) : 0.0
	end

	function safe_status(result)
		return result isa Dict ? string(get(result, "termination_status", "missing")) : "exception"
	end

	function safe_sum_load_curtailment(opf_result)
		if !has_valid_solution(opf_result) || !haskey(opf_result["solution"], "load")
			return 0.0
		end
		return sum(get(load, "pcurt", 0.0) for (_, load) in opf_result["solution"]["load"])
	end

	function try_solve_acdcopf(data, model, solver; setting)
		try
			return PMACDC.solve_acdcopf(data, model, solver; setting = setting)
		catch err
			@warn "AC/DC OPF failed; storing empty result and continuing." exception=(err, catch_backtrace())
			return Dict{String,Any}(
				"termination_status" => "exception",
				"objective" => 0.0,
				"solution" => Dict{String,Any}(),
			)
		end
	end

	function try_solve_zonal_opf(data, model, solver)
		try
			return PM.solve_opf(data, model, solver)
		catch err
			@warn "Zonal OPF failed; storing empty result and continuing." exception=(err, catch_backtrace())
			return Dict{String,Any}(
				"termination_status" => "exception",
				"objective" => 0.0,
				"solution" => Dict{String,Any}(),
			)
		end
	end

	function limit_internal_lines!(zone_grid::Dict{String,Any}; rate_limit = 15.0, angmin = -3pi, angmax = 3pi)
		for (b, branch) in zone_grid["branch"]
			branch["angmin"] = angmin
			branch["angmax"] = angmax

			is_xb_line = false
			if haskey(zone_grid, "borders")
				for (_, border) in zone_grid["borders"]
					if haskey(border, "xb_lines") && haskey(border["xb_lines"], b)
						is_xb_line = true
						break
					end
				end
			end

			if get(branch, "rate_a", 0.0) >= 49.9 && !is_xb_line
				branch["rate_a"] = rate_limit
				branch["rate_b"] = rate_limit
				branch["rate_c"] = rate_limit
			end
		end
		return zone_grid
	end

	function manual_cleanup_2020_de!(zone_grid)
		# Cleanup from the provided TYNDP 2020 / DE / 2007 example.
		# All deletes are guarded to avoid errors if a package/data update changes IDs.
		if haskey(zone_grid, "gen") && haskey(zone_grid["gen"], "4906")
			delete!(zone_grid["gen"], "4906")
		end
		if haskey(zone_grid, "bus") && haskey(zone_grid["bus"], "234")
			delete!(zone_grid["bus"], "234")
		end
		if haskey(zone_grid, "branch") && haskey(zone_grid["branch"], "392")
			delete!(zone_grid["branch"], "392")
		end
		if haskey(zone_grid, "borders") && haskey(zone_grid["borders"], "5") && haskey(zone_grid["borders"]["5"], "xb_lines") && haskey(zone_grid["borders"]["5"]["xb_lines"], "392")
			delete!(zone_grid["borders"]["5"]["xb_lines"], "392")
		end
		return zone_grid
	end
end

# ╔═╡ ab04dedd-5749-4c02-90aa-45309112952a
md"""
!!! info "Run zonal hourly OPF"
    This computes the zonal OPF results used to derive hourly cross-border flows for the nodal German model. Failed hours are stored as empty results and do not stop the notebook.
"""

# ╔═╡ 4e1fd1ca-2bc0-4fa5-a789-21dda48ef2de
begin
	println("######################################")
	println("### STARTING ZONAL HOURLY OPF ########")
	println("######################################")

	hours = selected_hours(start_hour, number_of_hours)
	zonal_result = Dict{String, Any}(string(hour) => nothing for hour in hours)
	input_data_hourly = deepcopy(input_data)

	for hour in hours
		println("Zonal OPF hour ", hour)
		EUGO.prepare_hourly_data!(input_data_hourly, nodal_data, hour)
		zonal_result[string(hour)] = try_solve_zonal_opf(input_data_hourly, zonal_model, solver)
	end

	zonal_result_summary = DF.DataFrame(
		hour = hours,
		objective = [safe_objective(zonal_result[string(h)]) for h in hours],
		termination_status = [safe_status(zonal_result[string(h)]) for h in hours],
	)
end

# ╔═╡ b028b7dd-dcab-44b3-b900-73110e985f51
md"""
!!! info "Save zonal OPF outputs"
    The file names include the `DE2040_2007` case information.
"""

# ╔═╡ 65681a8b-409e-4e6b-9478-9ba9a7ab275e
begin
	result_file_name = joinpath(result_dir, join(["result_zonal_tyndp_", scenario * year, "_", climate_year, ".json"]))
	input_file_name = joinpath(result_dir, join(["input_zonal_tyndp_", scenario * year, "_", climate_year, ".json"]))
	scenario_file_name = joinpath(result_dir, join(["scenario_zonal_tyndp_", scenario * year, "_", climate_year, ".json"]))

	if save_zonal_results
		open(result_file_name, "w") do f
			JSON.print(f, zonal_result, 4)
		end
		open(input_file_name, "w") do f
			JSON.print(f, input_data_raw, 4)
		end
		open(scenario_file_name, "w") do f
			JSON.print(f, nodal_data, 4)
		end
	end

	(result_file_name, input_file_name, scenario_file_name)
end

# ╔═╡ 6aa839e5-3843-49e8-9a96-d89018917f06
md"""
!!! info "Optional zonal-flow plot"
    Disabled by default because the main CBA does not require the plot.
"""

# ╔═╡ 701dc873-8600-40a4-abb4-d516167021c0
begin
	zonal_flow_plot_file = joinpath(result_dir, "zonal_flows_" * scenario * year * "_" * climate_year * ".pdf")
	plot_zonal_flows = nothing

	if make_zonal_flow_plot
		flows_ac, flows_dc, zonal_flow_result_dict = EUGO.get_branch_flows(zonal_result)
		plot_zonal_flows = EUGO.plot_grid(
			input_data_raw,
			zonal_flow_plot_file;
			ac_only = true,
			color_branches = true,
			flows_ac = flows_ac,
		)
	end

	zonal_flow_plot_file
end

# ╔═╡ 78dcc0c3-493e-4adf-b6d4-c5e1667c8778
md"""
!!! info "Load and prepare the nodal German network"
    This uses `European_grid_no_nseh.json`, isolates `DE` and `DEKF` with `border_slack = 0.003`, applies the guarded manual clean-up, and limits internal branches to 15 p.u.
"""

# ╔═╡ bfd09aa4-d8ef-423a-8636-249f970605cf
begin
	grid_data_file = joinpath(pkgdir(EUGO), "data_sources", "European_grid_no_nseh.json")

	EU_grid = PMACDC.parse_file(grid_data_file)
	EUGO.add_load_and_pst_properties!(EU_grid)

	zone_mapping = EUGO.map_zones()

	# TYNDP 2020 signature used in the provided script.
	EUGO.scale_generation!(capacity, EU_grid, scenario, climate_year, zone_mapping; tyndp = tyndp_version)

	# Fix high-impedance line ratings to avoid XB infeasibilities.
	EUGO.fix_data!(EU_grid)

	zone_grid = EUGO.isolate_zones(EU_grid, zones_to_keep; border_slack = border_slack)

	if apply_manual_grid_cleanup
		manual_cleanup_2020_de!(zone_grid)
	end

	timeseries_data = EUGO.create_res_and_demand_time_series(
		wind_onshore,
		wind_offshore,
		pv,
		nodal_data,
		climate_year,
		zone_mapping;
		zones = ["DE"],
	)

	push!(timeseries_data, "xb_flows" => EUGO.get_xb_flows(zone_grid, zonal_result, input_data_raw, zone_mapping))

	EUGO.get_demand_reponse!(zone_grid, input_data_raw, zone_mapping, timeseries_data)

	if limit_internal_5000mva_lines
		limit_internal_lines!(zone_grid; rate_limit = internal_rate_limit_pu, angmin = internal_angmin, angmax = internal_angmax)
	end

	zone_grid_base = deepcopy(zone_grid)

	candidate_grids = Dict{String,Any}()
	for (case_name, case_links) in candidate_cases
		candidate_grids[case_name] = EUGO.add_hvdc_links(deepcopy(zone_grid), case_links)
	end

	case_names = [case_name for (case_name, _) in candidate_cases]

	nodal_grid_summary = DF.DataFrame(
		case = vcat(["Base"], case_names),
		ac_buses = vcat([length(zone_grid_base["bus"])], [length(candidate_grids[c]["bus"]) for c in case_names]),
		ac_branches = vcat([length(zone_grid_base["branch"])], [length(candidate_grids[c]["branch"]) for c in case_names]),
		dc_buses = vcat([length(get(zone_grid_base, "busdc", Dict()))], [length(get(candidate_grids[c], "busdc", Dict())) for c in case_names]),
		dc_branches = vcat([length(get(zone_grid_base, "branchdc", Dict()))], [length(get(candidate_grids[c], "branchdc", Dict())) for c in case_names]),
		converters = vcat([length(get(zone_grid_base, "convdc", Dict()))], [length(get(candidate_grids[c], "convdc", Dict())) for c in case_names]),
	)
end

# ╔═╡ f1e89011-0f4c-4d4b-ad63-23d17d279a3e
md"""
!!! info "Run nodal German-grid OPF CBA"
    This cell first initialises all metric arrays as zeros. If an OPF result is infeasible or empty, the corresponding entries simply remain zero and the loop continues.
"""

# ╔═╡ b7e81358-4c77-4e93-b503-5c9069753e7d
begin
	function run_nodal_cba_zero_on_infeasible(
		zone_grid_base,
		candidate_grids,
		case_names,
		timeseries_data,
		hours;
		start_hour,
		number_of_hours,
		nodal_model,
		solver,
		nodal_opf_setting,
		emission_factor,
	)
		# One vector per candidate case, matching the structure of the provided example.
		arrays_by_case = Dict{String,Any}()
		nodal_results = Dict{String,Any}()

		for case_name in case_names
			arrays_by_case[case_name] = Dict{String,Any}(
				"total_operating_cost_base" => zeros(number_of_hours),
				"total_operating_cost_hvdc" => zeros(number_of_hours),
				"total_ens_base" => zeros(number_of_hours),
				"total_ens_hvdc" => zeros(number_of_hours),
				"total_emissions_base" => zeros(number_of_hours),
				"total_emissions_hvdc" => zeros(number_of_hours),
				"total_res_base" => zeros(number_of_hours),
				"total_res_hvdc" => zeros(number_of_hours),
				"total_xb_base" => zeros(number_of_hours),
				"total_xb_hvdc" => zeros(number_of_hours),
				"total_res_curt_base" => zeros(number_of_hours),
				"total_res_curt_hvdc" => zeros(number_of_hours),
				"cost_base" => zeros(number_of_hours),
				"cost_hvdc" => zeros(number_of_hours),
				"status_base" => fill("not_run", number_of_hours),
				"status_hvdc" => fill("not_run", number_of_hours),
			)
		end

		hourly_cba = DF.DataFrame(
			case = String[],
			hour = Int[],
			objective_base = Float64[],
			objective_candidate = Float64[],
			operating_cost_benefit = Float64[],
			ens_base_pu = Float64[],
			ens_candidate_pu = Float64[],
			res_base_pu = Float64[],
			res_candidate_pu = Float64[],
			res_curt_base_pu = Float64[],
			res_curt_candidate_pu = Float64[],
			emissions_base = Float64[],
			emissions_candidate = Float64[],
			status_base = String[],
			status_candidate = String[],
		)

		h_idx = 1
		last_opf_base = nothing
		last_candidate_results = Dict{String,Any}()

		for h in hours
			println("Hour ", h)

			zone_grid_h = deepcopy(zone_grid_base)
			EUGO.hourly_grid_data!(zone_grid_h, zone_grid_base, h, timeseries_data; start_hour = start_hour)
			opf_base = try_solve_acdcopf(zone_grid_h, nodal_model, solver; setting = nodal_opf_setting)
			last_opf_base = opf_base

			base_ok = has_valid_solution(opf_base)
			base_status = safe_status(opf_base)

			# Base metrics. If infeasible/empty, all remain zero.
			base_objective = 0.0
			base_ens = 0.0
			base_res = 0.0
			base_res_curt = 0.0
			base_emissions = 0.0

			if base_ok
				base_objective = get(opf_base, "objective", 0.0)
				base_ens = safe_sum_load_curtailment(opf_base)
				base_res = EUGO.calculate_res_generation(opf_base, zone_grid_h)
				base_res_curt = EUGO.calculate_res_curtailment(opf_base, zone_grid_h)
				base_emissions = EUGO.calculate_emissions(opf_base, zone_grid_h, emission_factor)
			end

			for case_name in case_names
				println("  Candidate case: ", case_name)
				arr = arrays_by_case[case_name]

				zone_grid_h_un = deepcopy(candidate_grids[case_name])
				EUGO.hourly_grid_data!(zone_grid_h_un, candidate_grids[case_name], h, timeseries_data; start_hour = start_hour)
				opf_hvdc = try_solve_acdcopf(zone_grid_h_un, nodal_model, solver; setting = nodal_opf_setting)
				last_candidate_results[case_name] = opf_hvdc

				hvdc_ok = has_valid_solution(opf_hvdc)
				hvdc_status = safe_status(opf_hvdc)

				# Candidate metrics. If infeasible/empty, all remain zero.
				hvdc_objective = 0.0
				hvdc_ens = 0.0
				hvdc_res = 0.0
				hvdc_res_curt = 0.0
				hvdc_emissions = 0.0

				if hvdc_ok
					hvdc_objective = get(opf_hvdc, "objective", 0.0)
					hvdc_ens = safe_sum_load_curtailment(opf_hvdc)
					hvdc_res = EUGO.calculate_res_generation(opf_hvdc, zone_grid_h_un)
					hvdc_res_curt = EUGO.calculate_res_curtailment(opf_hvdc, zone_grid_h_un)
					hvdc_emissions = EUGO.calculate_emissions(opf_hvdc, zone_grid_h_un, emission_factor)
				end

				# Store arrays. Infeasible cases remain zero by construction.
				arr["total_operating_cost_base"][h_idx] = base_objective
				arr["total_ens_base"][h_idx] = base_ens
				arr["total_res_base"][h_idx] = base_res
				arr["total_res_curt_base"][h_idx] = base_res_curt
				arr["total_emissions_base"][h_idx] = base_emissions

				arr["total_operating_cost_hvdc"][h_idx] = hvdc_objective
				arr["total_ens_hvdc"][h_idx] = hvdc_ens
				arr["total_res_hvdc"][h_idx] = hvdc_res
				arr["total_res_curt_hvdc"][h_idx] = hvdc_res_curt
				arr["total_emissions_hvdc"][h_idx] = hvdc_emissions
				arr["status_base"][h_idx] = base_status
				arr["status_hvdc"][h_idx] = hvdc_status

				push!(hourly_cba, (
					case_name,
					Int(h),
					base_objective,
					hvdc_objective,
					base_objective - hvdc_objective,
					base_ens,
					hvdc_ens,
					base_res,
					hvdc_res,
					base_res_curt,
					hvdc_res_curt,
					base_emissions,
					hvdc_emissions,
					base_status,
					hvdc_status,
				))

				if !base_ok || !hvdc_ok
					println("  Skipping metrics for infeasible/empty result at hour ", h, ", case ", case_name,
						". base_ok=", base_ok, ", hvdc_ok=", hvdc_ok)
				end
			end

			nodal_results[string(h)] = Dict(
				"base_status" => base_status,
				"candidate_status" => Dict(case_name => arrays_by_case[case_name]["status_hvdc"][h_idx] for case_name in case_names),
			)

			h_idx += 1
		end

		return hourly_cba, arrays_by_case, nodal_results, last_opf_base, last_candidate_results
	end
end

# ╔═╡ 180849ef-93cb-4b5b-9284-f5be6b783806
begin
	hourly_cba, arrays_by_case, nodal_results, last_opf_base, last_candidate_results = run_nodal_cba_zero_on_infeasible(
		zone_grid_base,
		candidate_grids,
		case_names,
		timeseries_data,
		hours;
		start_hour = start_hour,
		number_of_hours = number_of_hours,
		nodal_model = nodal_model,
		solver = solver,
		nodal_opf_setting = nodal_opf_setting,
		emission_factor = emission_factor,
	)
end

# ╔═╡ 5aabecbb-ef16-43e6-946e-c8b79b5a2b62
md"""
!!! info "Aggregate CBA indicators by candidate case"
    Because infeasible/empty results are stored as zeros, they contribute zero to these aggregate metrics.
"""

# ╔═╡ ffd2e0d5-a43b-45c1-ae98-745d688fac8d
begin
	function summarise_arrays_by_case(arrays_by_case, zone_grid_base)
		rows = []
		for (case_name, arr) in arrays_by_case
			res_increase = sum(arr["total_res_hvdc"] .- arr["total_res_base"])
			social_welfare_increase = sum(arr["total_operating_cost_base"] .- arr["total_operating_cost_hvdc"]) / 1e6
			emissions_decrease = sum(arr["total_emissions_base"] .- arr["total_emissions_hvdc"])
			adequacy_increase = sum(arr["total_ens_base"] .- arr["total_ens_hvdc"]) * zone_grid_base["baseMVA"]
			res_curtailment_decrease = sum(arr["total_res_curt_base"] .- arr["total_res_curt_hvdc"]) * zone_grid_base["baseMVA"]

			push!(rows, (
				case = case_name,
				social_welfare_increase_meur = social_welfare_increase,
				res_generation_increase_mwh = res_increase * zone_grid_base["baseMVA"],
				res_curtailment_decrease_mwh = res_curtailment_decrease,
				emissions_decrease = emissions_decrease,
				adequacy_increase_mwh = adequacy_increase,
				base_success_hours = count(x -> x != "exception" && x != "missing" && x != "not_run", arr["status_base"]),
				candidate_success_hours = count(x -> x != "exception" && x != "missing" && x != "not_run", arr["status_hvdc"]),
			))
		end
		return DF.DataFrame(rows)
	end

	cba_summary_by_case = summarise_arrays_by_case(arrays_by_case, zone_grid_base)
end

# ╔═╡ 4ac22421-77d4-4671-93d3-b7b8257bdcae
begin
	for row in eachrow(cba_summary_by_case)
		println("==============================")
		println("Case: ", row.case)
		println("Social welfare increase [MEUR]: ", row.social_welfare_increase_meur)
		println("RES generation increase [MWh]: ", row.res_generation_increase_mwh)
		println("RES curtailment decrease [MWh]: ", row.res_curtailment_decrease_mwh)
		println("Emissions decrease [tCO2]: ", row.emissions_decrease)
		println("Adequacy increase / ENS decrease [MWh]: ", row.adequacy_increase_mwh)
		println("Candidate non-empty result hours: ", row.candidate_success_hours)
	end
end

# ╔═╡ 339565b5-bab0-4a15-9bcc-c6f50ef52182
md"""
!!! info "Plots"
    These plots use the zero-filled arrays, so infeasible or empty results appear as zero objective/benefit points.
"""

# ╔═╡ 35812238-211d-4d07-ae8e-32e951148db0
begin
	p_objective = Plots.plot(
		title = "Nodal German OPF objective comparison",
		xlabel = "Hour",
		ylabel = "Objective value",
		fontfamily = "Computer Modern",
	)

	first_case = first(case_names)
	Plots.plot!(p_objective, hours, arrays_by_case[first_case]["total_operating_cost_base"], label = "Base", linewidth = 3)

	for case_name in case_names
		Plots.plot!(p_objective, hours, arrays_by_case[case_name]["total_operating_cost_hvdc"], label = case_name, linewidth = 2)
	end

	p_objective
end

# ╔═╡ eb242616-2069-4d51-b87f-2b196552971a
begin
	p_benefit = Plots.plot(
		title = "Hourly operating-cost benefit by HVDC case",
		xlabel = "Hour",
		ylabel = "Benefit [MEUR]",
		fontfamily = "Computer Modern",
	)

	for case_name in case_names
		arr = arrays_by_case[case_name]
		Plots.plot!(p_benefit, hours, (arr["total_operating_cost_base"] .- arr["total_operating_cost_hvdc"]) ./ 1e6, label = case_name, linewidth = 2)
	end

	p_benefit
end

# ╔═╡ fcf127f7-17b7-42fe-b290-013834713f8e
begin
	p_summary = Plots.bar(
		cba_summary_by_case.case,
		cba_summary_by_case.social_welfare_increase_meur,
		label = "Operating-cost benefit",
		xrotation = 20,
		xlabel = "Candidate case",
		ylabel = "Benefit [MEUR]",
		title = "Total benefit over selected hours",
		fontfamily = "Computer Modern",
	)
end

# ╔═╡ 6a22d23d-1de1-4fc2-b8d2-8e01f9515782
md"""
!!! info "Save nodal CBA results"
    This writes hourly CBA rows, summary rows, and a compact JSON file. The output file names include `TYNDP2020`, `DE2040`, and `2007`.
"""

# ╔═╡ 8b43f524-a592-4106-84c3-c39d90fefc25
begin
	nodal_cba_csv = joinpath(result_dir, join(["nodal_cba_by_link_tyndp_", scenario * year, "_", climate_year, ".csv"]))
	nodal_cba_summary_csv = joinpath(result_dir, join(["nodal_cba_by_link_summary_tyndp_", scenario * year, "_", climate_year, ".csv"]))
	nodal_cba_json = joinpath(result_dir, join(["nodal_cba_by_link_tyndp_", scenario * year, "_", climate_year, ".json"]))

	if save_cba_results
		CSV.write(nodal_cba_csv, hourly_cba)
		CSV.write(nodal_cba_summary_csv, cba_summary_by_case)

		cba_output = Dict{String,Any}(
			"tyndp_version" => tyndp_version,
			"scenario" => scenario,
			"year" => year,
			"climate_year" => climate_year,
			"start_hour" => start_hour,
			"number_of_hours" => number_of_hours,
			"branch_rate_limit_pu" => internal_rate_limit_pu,
			"border_slack" => border_slack,
			"hours" => hours,
			"candidate_cases" => Dict(case_name => links for (case_name, links) in candidate_cases),
			"summary_by_case" => Dict(row.case => Dict(
				"social_welfare_increase_meur" => row.social_welfare_increase_meur,
				"res_generation_increase_mwh" => row.res_generation_increase_mwh,
				"xb_increase_mwh" => row.xb_increase_mwh,
				"res_curtailment_decrease_mwh" => row.res_curtailment_decrease_mwh,
				"emissions_decrease" => row.emissions_decrease,
				"adequacy_increase_mwh" => row.adequacy_increase_mwh,
				"base_success_hours" => row.base_success_hours,
				"candidate_success_hours" => row.candidate_success_hours,
			) for row in eachrow(cba_summary_by_case)),
			"hourly_status" => nodal_results,
		)

		open(nodal_cba_json, "w") do f
			JSON.print(f, cba_output, 4)
		end
	end

	(nodal_cba_csv, nodal_cba_summary_csv, nodal_cba_json)
end

# ╔═╡ 908582dd-02d3-4fa6-a6fb-f9fcd190e0a7
md"""
!!! tip "What changed from the previous notebook"
    - `tyndp_version = "2020"`
    - `climate_year = "2007"`
    - `start_hour = 48`
    - `border_slack = 0.003`
    - zones isolated as `["DE", "DEKF"]`
    - manual cleanup for generator `4906`, bus `234`, branch `392`, and border line `392`, guarded with `haskey`
    - branch rating cap is now `15.0` p.u.
    - if base or candidate OPF has no usable solution, the metrics for that hour/case stay at zero and the loop continues.
"""

# ╔═╡ Cell order:
# ╠═a5eb6d1d-83a7-418d-b76a-c0cf420c6391
# ╠═3b078b52-a2c1-4ada-951c-5ab4280e685a
# ╠═c9442eef-e502-4033-a274-5e93ba1ab06b
# ╠═4db01edf-a679-4abb-81f4-8819f09986e6
# ╠═634fe521-b0ee-4233-9809-fc0df049c4d7
# ╠═1d6aaaca-7732-4783-b22e-c7cfd8b6f7fc
# ╠═a1aad4c7-de37-4037-89fa-25d0ba7fba2b
# ╠═d528ba87-3370-4ebb-8eab-633e2985cd09
# ╠═935a4cc8-3a3f-48a3-90f2-851764726fff
# ╠═d38cb709-1fda-4b63-83a6-7406f5e34ade
# ╠═15eb467a-c6e9-4b42-b384-2609362dc600
# ╠═d9d7a968-98cf-480b-9c65-05115368474f
# ╠═ab04dedd-5749-4c02-90aa-45309112952a
# ╠═4e1fd1ca-2bc0-4fa5-a789-21dda48ef2de
# ╠═b028b7dd-dcab-44b3-b900-73110e985f51
# ╠═65681a8b-409e-4e6b-9478-9ba9a7ab275e
# ╠═6aa839e5-3843-49e8-9a96-d89018917f06
# ╠═701dc873-8600-40a4-abb4-d516167021c0
# ╠═78dcc0c3-493e-4adf-b6d4-c5e1667c8778
# ╠═bfd09aa4-d8ef-423a-8636-249f970605cf
# ╠═f1e89011-0f4c-4d4b-ad63-23d17d279a3e
# ╠═b7e81358-4c77-4e93-b503-5c9069753e7d
# ╠═180849ef-93cb-4b5b-9284-f5be6b783806
# ╠═5aabecbb-ef16-43e6-946e-c8b79b5a2b62
# ╠═ffd2e0d5-a43b-45c1-ae98-745d688fac8d
# ╠═4ac22421-77d4-4671-93d3-b7b8257bdcae
# ╠═339565b5-bab0-4a15-9bcc-c6f50ef52182
# ╠═35812238-211d-4d07-ae8e-32e951148db0
# ╠═eb242616-2069-4d51-b87f-2b196552971a
# ╠═fcf127f7-17b7-42fe-b290-013834713f8e
# ╠═6a22d23d-1de1-4fc2-b8d2-8e01f9515782
# ╠═8b43f524-a592-4106-84c3-c39d90fefc25
# ╠═908582dd-02d3-4fa6-a6fb-f9fcd190e0a7
