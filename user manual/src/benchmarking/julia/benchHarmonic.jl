## inputs
tSpan = [0, 10]     # [intial time, final time]
y0 = [1 1]             # intial value ([of order 0      of order 1])
α = 1.90         # order of the derivative
par = [16.0, 4.0] # [spring constant for a mass on a spring, inertial mass]

## Equation
function F(t, x, par)

      K, m = par

      - K ./ m .* x

end
function JF(t, x, par)

      K, m = par

      - K ./ m

end

##scifracx
F2(y, par, t) = - 16 ./ 4 .* y

prob = SingleTermFODEProblem(F2, α, [1, 1], (0, 10));

#exact solution: mittag-leffler
Exact(t) = y0[1] .* mittleff(α,1, -par[1]./par[2] .* t .^ α) .+ y0[2] .* t .* mittleff(α,2, -par[1]./par[2] .* t .^ α)

# Benchmarking
E1 = Float64[];T1 = Float64[];E2 = Float64[];T2 = Float64[]
E3 = Float64[];T3 = Float64[];E4 = Float64[];T4 = Float64[]
E5 = Float64[];T5 = Float64[];E6 = Float64[];T6 = Float64[];
h = Float64[]

for n in range(2, length=6)
    println("n: $n")# to print out the current step of runing
    h = 2.0^-n #stepsize of computting
        #computting the time
    t1= @benchmark FDEsolver($(F), $(tSpan), $(y0), $(α), $(par) , h=$(h)) seconds=1
    t2= @benchmark FDEsolver($(F), $(tSpan), $(y0), $(α), $(par), JF = $(JF), h=$(h)) seconds=1
    t3= @benchmark solve($(prob), $(h), $(PECE())); seconds=1
    t4 = @benchmark solve($(prob), $(h), PIEX()); seconds=1
    t5= @benchmark solve($(prob), $(h), $(GL())); seconds=1
    t6= @benchmark solve($(prob), $(h), $(Euler())); seconds=1
    # convert from nano seconds to seconds
    push!(T1, mean(t1).time / 10^9)
    push!(T2, mean(t2).time / 10^9)
    push!(T3, mean(t3).time / 10^9)
    push!(T4, mean(t4).time / 10^9)
    push!(T5, mean(t5).time / 10^9)
    push!(T6, mean(t6).time / 10^9)

    #computting the error
    t, y1 = FDEsolver(F, tSpan, y0, α, par , h=h)
    _, y2 = FDEsolver(F, tSpan, y0, α, par, JF = JF, h=h)
    y3 =  solve(prob, h, PECE());
    y4 = solve(prob, h, PIEX());
    y5 = solve(prob, h, GL());
    y6 =  solve(prob, h, Euler());

    #exact solution
    ery1=norm(y1 - map(Exact, t), 2)
    ery2=norm(y2 - map(Exact, t), 2)
    ery3=norm(y3.u - map(Exact, y3.t),2);
    ery4=norm(y4.u - map(Exact, y4.t),2);
    ery5=norm(y5.u - map(Exact, y5.t),2);
    ery6=norm(y6.u - map(Exact, y6.t),2);

    push!(E1, ery1)
    push!(E2, ery2)
    push!(E3, ery3)
    push!(E4, ery4)
    push!(E5, ery5)
    push!(E6, ery6)

end

## plotting
# plot Matlab and FdeSolver outputs
plot(T1, E1, xscale = :log, yscale = :log, label = "J-1", shape = :diamond,
 xlabel="Execution time (sc, Log)", ylabel="Error: 2-norm (Log)",
     thickness_scaling = 1, fc=:transparent,framestyle=:box, color="firebrick3")
 plot!(T2, E2,label = "J-2", shape = :diamond, color="firebrick3")
 plot!(T3, E3,label = "J-PECE", shape = :rtriangle, color="darkorange")
 plot!(T4, E4,label = "J-PIEX", shape = :star5, color="darkorange")
 plot!(T5, E5,label = "J-GL", shape = :square, color="darkorange")
 plot!(T6, E6,label = "J-Euler", shape = :circle, color="darkorange")
 plot!(Mdata[:, 1], Mdata[:, 5],label = "M-1",shape = :rect, color="royalblue3")
 plot!(Mdata[:, 3], Mdata[:, 7], label = "M-2", shape = :rect, color="royalblue3")
 plot!(Mdata[:, 2], Mdata[:, 6], label = "M-3", shape = :rect, color="royalblue3")
 pHar=plot!(Mdata[:, 4], Mdata[:, 8], label = "M-4", shape = :rect, legend_position=:bottomleft, color="royalblue3")

# savefig(pHar, "pHar.png")
# savefig(pHar,"Harmonic.svg")

#save data
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_E1.csv"),  Tables.table(E1))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_E2.csv"),  Tables.table(E2))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_E3.csv"),  Tables.table(E3))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_E4.csv"),  Tables.table(E4))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_E5.csv"),  Tables.table(E5))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_E6.csv"),  Tables.table(E6))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_T1.csv"),  Tables.table(T1))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_T2.csv"),  Tables.table(T2))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_T3.csv"),  Tables.table(T3))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_T4.csv"),  Tables.table(T4))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_T5.csv"),  Tables.table(T5))
CSV.write(joinpath(data_dir, "data_Julia/Harmonic_T6.csv"),  Tables.table(T6))
