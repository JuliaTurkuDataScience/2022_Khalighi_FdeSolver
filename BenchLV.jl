using LinearAlgebra
using BenchmarkTools
using FdeSolver
using FractionalDiffEq, Plots
using SpecialFunctions
using CSV, DataFrames

## insert data
#it should be based on the directory of CSV files on your computer
push!(LOAD_PATH, "./FDEsolver")
Mdata = Matrix(CSV.read("BenchLV.csv", DataFrame, header = 0)) #Benchmark from Matlab

## inputs
tSpan = [0, 60]       # [intial time, final time]
y0 = [1,1,1]   # initial values [X1(0),X2(0),X3(0)]
α = [1, .9, .7]          # order of derivatives

## ODE model
par = [3,3,3,5,3,3,3] 

function F(t, x, par)

    # parameters
    a1, a2, a3, a4, a5, a6, a7 = par

    # System equation
    dx1 = x[1]*(a1-a2*x[2]-x[3])
    dx2 = x[2]*(1-a3+a4*x[1])
    dx3 = x[3]*(1-a5+a6*x[1]+a7*x[2])

    return [dx1, dx2, dx3]

end

## Jacobian of ODE system
function JF(t, x, par)

    # parameters
    a1, a2, a3, a4, a5, a6, a7 = par

    # System equation
    J11 = a1-2*a2*x[1]-x[2]-x[3]
    J12 = -x[1]
    J13 = -x[1]
    J21 = a4*x[2]
    J22 = 1-a3+a4*x[1]
    J23 = 0
    J31 = a6*x[3]
    J32 = a7*x[3]
    J33 = a6*x[1]-a5+a7*x[2]+1

    J = [J11 J12 J13
         J21 J22 J23
         J31 J32 J33]

    return J

end

##scifracx
function LV!(dx, x, p, t)

    # parameters
    a1, a2, a3, a4, a5, a6, a7 = [3,3,3,5,3,3,3] # this package is not ready for calling the parameters!
    # System equation
    dx[1] = x[1]*(a1-a2*x[2]-x[3])
    dx[2] = x[2]*(1-a3+a4*x[1])
    dx[3] = x[3]*(1-a5+a6*x[1]+a7*x[2])
end

Tspan = (0, 60)

y00 = [1;1;1]
prob = FODESystem(LV!, α, y00, Tspan)

t, Yex= FDEsolver(F, tSpan, y0, α, par, JF = JF, h=2^-10, tol=1e-12) # Solution with a fine step size

# Benchmarking
E1 = Float64[];T1 = Float64[];E2 = Float64[];T2 = Float64[]
E3 = Float64[];T3 = Float64[];
h = Float64[]


for n in range(4,8)
    println("n: $n")# to print out the current step of runing
    h = 2.0^-n #stepsize of computting
        #computting the time
    t1= @benchmark FDEsolver(F, $(tSpan), $(y0), $(α), $(par) , h=$(h), nc=4, tol =1e-8) seconds=1
    t2= @benchmark FDEsolver(F, $(tSpan), $(y0), $(α), $(par), JF = JF, h=$(h), tol=1e-8) seconds=1
    t3 = @benchmark solve($(prob), $(h), PECE()) seconds=1

    # convert from nano seconds to seconds
    push!(T1, minimum(t1).time / 10^9)
    push!(T2, minimum(t2).time / 10^9)
    push!(T3, minimum(t3).time / 10^9)
    #computting the error
    _, y1 = FDEsolver(F, tSpan, y0, α, par , h=h, nc=4, tol =1e-8)
    _, y2 = FDEsolver(F, tSpan, y0, α, par, JF = JF, h=h, tol=1e-8)
    y3 = solve(prob, h, PECE())

    ery1=norm(y1 .- Yex[1:2^(10-n):end,:],2)
    ery2=norm(y2 .- Yex[1:2^(10-n):end,:],2)
    ery3=norm(y3.u' .- Yex[1:2^(10-n):end,:],2)

    push!(E1, ery1)
    push!(E2, ery2)
    push!(E3, ery3)

end

## plotting
# plot Matlab and FdeSolver outputs
plot(T1, E1, xscale = :log, yscale = :log, linewidth = 2, markersize = 5,
     label = "Julia PC (FdeSolver.jl)", shape = :circle, xlabel="Time (sc, Log)", ylabel="Error: 2-norm (Log)",
     thickness_scaling = 1,legend_position= :right, c=:blue,fc=:transparent,framestyle=:box, mc=:white)
plot!(T2, E2,linewidth = 2, markersize = 5,label = "Julia NR (FdeSolver.jl)", shape = :rect, color = :blue, mc=:white)
plot!(Mdata[2:end, 1], Mdata[2:end, 5], linewidth = 2, markersize = 5,label = "Matlab PI-EX (Garrappa)",shape = :rtriangle, color = :red, mc=:white)
plot!(Mdata[:, 2], Mdata[:, 6], linewidth = 2, markersize = 5,label = "Matlab PI-PC (Garrappa)", shape = :circle, color = :red, mc=:white)
plot!(Mdata[:, 3], Mdata[:, 7], linewidth = 2, markersize = 5,label = "Matlab PI-IM1 (Garrappa)", shape = :diamond, color = :red, mc=:white)
pLV3=plot!(Mdata[:, 4], Mdata[:, 8], linewidth = 2, markersize = 5,label = "Matlab PI-IM2 (Garrappa)", shape = :rect, color = :red, mc=:white)


savefig(pLV3,"LV3.svg")
# plot Scifracx outputs
plotd2=plot!(T9, E9,linewidth = 2,  markersize = 5, label = "Julia PECE (FractionalDiffEq.jl)", shape = :diamond, color = :purple,mc=:white)
savefig(plotd2,"LV3_1.png")
