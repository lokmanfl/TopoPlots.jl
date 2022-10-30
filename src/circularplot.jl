using Pkg
Pkg.activate("dev/TopoPlots.jl/")
using CairoMakie
using TopoPlots

# https://docs.makie.org/stable/tutorials/layout-tutorial/

canvasResolution = 1000
bgcolor = RGBf(0.98, 0.98, 0.98)
# canvas
f = Figure(backgroundcolor = bgcolor,resolution = (canvasResolution, canvasResolution))

function dummyPlotFunc(data, topoplotLabels, predictorBounds::Vector{Int64}, predictorValues::Vector{Int64}, circleLabel::String)
    if(length(predictorBounds) != 2)
        error("the predictorBounds vector needs exactly two values")
    end
    if(predictorBounds[1] >= predictorBounds[2])
        error("predictorBounds[1] needs to be smaller than predictorBounds[2]")
    end
    if((length(predictorValues[predictorValues .< predictorBounds[1]]) != 0) || (length(predictorValues[predictorValues .> predictorBounds[2]]) != 0))
        error("all values in the predictorValues have to be within the predictorBounds range")
    end
    if(length(data) != length(predictorValues))
        error("data and predictorValues have to be of the same size")
    end
    if(length(data) != length(topoplotLabels))
        error("data and topoplotLabels have to be of the same size")
    end

    plotCircularAxis(f, predictorBounds,circleLabel)
    plotTopoPlots(data, topoplotLabels, predictorValues, predictorBounds)
end

function plotCircularAxis(f, predictorBounds, label)
    circleAxis = Axis(f[1,1], backgroundcolor = bgcolor)
    xlims!(-9,9)
    ylims!(-9,9)
    hidedecorations!(circleAxis)
    hidespines!(circleAxis)
    lines!(circleAxis, 3 * cos.(LinRange(0,2*pi,500)), 3 * sin.(LinRange(0,2*pi,500)), color = (:black, 0.5),linewidth = 3)

    # labels and label lines for the circle
    circlepoints_lines = [(3.2 * cos(a), 3.2 * sin(a)) for a in LinRange(0, 2pi, 5)[1:end-1]]
    circlepoints_labels = [(3.6 * cos(a), 3.6 * sin(a)) for a in LinRange(0, 2pi, 5)[1:end-1]]
    text!(
        circlepoints_lines,
        # using underscores as lines around the circular axis
        text = ["_","_","_","_"],
        rotation = LinRange(0, 2pi, 5)[1:end-1],
        align = (:right, :baseline),
        textsize = 30
    )
    text!(
        circlepoints_labels,
        text = calculateAxisLabels(predictorBounds),
        align = (:center, :center),
        textsize = 30
    )
    text!(circleAxis, 0, 0, text = label, align = (:center, :center),textsize = 40)
end

function plotTopoPlots(data, topoplotLabels, predictorValues, predictorBounds)
    for (index, value) in enumerate(data)
        datapoints, positions = value
        eegaxis = Axis(f, bbox = calculateBBoxCoordiantes(predictorValues[index],predictorBounds), backgroundcolor = bgcolor)
        hidedecorations!(eegaxis)
        hidespines!(eegaxis)
        TopoPlots.eeg_topoplot!(datapoints[:, 340, 1], eegaxis, topoplotLabels[index]; positions=positions)
    end
end

# four labels around the circle, middle values are the 0.25 and 0.75 quantiles
function calculateAxisLabels(predictorBounds)
    nonboundlabels = quantile(predictorBounds,[0.25,0.5,0.75])
    # third label is on the left and it tends to cover the circle so added some blank spaces to tackle that
    return [string(trunc(Int,predictorBounds[1])), string(trunc(Int,nonboundlabels[1])), string(trunc(Int,nonboundlabels[2]), "   "), string(trunc(Int,nonboundlabels[3]))]
end

function calculateBBoxCoordiantes(predictorValue, bounds)
    percentage = (predictorValue-bounds[1])/(bounds[2]-bounds[1])
    radius = (canvasResolution * 0.7) / 2
    sizeOfBBox = canvasResolution / 5

    x = radius*cos(percentage*2*pi)
    y = radius*sin(percentage*2*pi)
    
    return BBox(canvasResolution/2-sizeOfBBox/2 + x, canvasResolution/2+sizeOfBBox-sizeOfBBox/2 + x, canvasResolution/2-sizeOfBBox/2 + y, canvasResolution/2+sizeOfBBox-sizeOfBBox/2 + y)
end

data = TopoPlots.example_data()
labels = ["s$i" for i in 1:size(data, 1)]

dummyPlotFunc([data,data,data,data,data,data,data,data], [labels,labels,labels,labels,labels,labels,labels,labels], [0,360], [0,50,80,120,180,210,280,330], "incoming\nsaccade\namplitude [°]")

f