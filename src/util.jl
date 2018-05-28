"""
    show(sresult::Simulation)

Print out summary of simulation.
"""
function show(io::IO, sresult::Simulation)

  @printf("Input parameters: \n")
  @printf("\t Mutation rate: %.2f\n", sresult.input.μ)
  @printf("\t Death rate of host population: %.2f\n", sresult.input.d)
  @printf("\t Effective mutation rate (μ/β): %.2f\n", sresult.input.μ / ((sresult.input.b-sresult.input.d)/sresult.input.b))
  @printf("\t Number of clonal mutation: %d\n", sresult.input.clonalmutations)

  @printf("\t Number of subclones: %d\n\n", sresult.input.numclones)
  if sresult.input.numclones > 0
    for i in 1:length(sresult.output.clonefreq)
      @printf("Subclone %d \n", i)
      @printf("\tFrequency: %.2f\n", sresult.output.clonefreq[i])
      @printf("\tNumber of mutations in subclone: %d\n", sresult.output.subclonemutations[i])
      @printf("\tFitness advantage: %.2f\n", sresult.input.selection[i])
      @printf("\tTime subclone emerges (population doublings): %.2f\n", log(sresult.output.cloneN[i])/log(2))
      @printf("\tNumber of divisions: %d\n", sresult.output.Ndivisions[i])
      @printf("\tAverage number of divisions per cell: %.2f\n", sresult.output.aveDivisions[i])
      @printf("\tPopulation size when subclone emerges: %d\n", sresult.output.cloneN[i])
      @printf("\tParent of subclone (0 is host): %d\n", sresult.output.clonetype[i])
    end
  else
    @printf("No clones, tumour growth was neutral\n\n")
  end

end

"""
    vafhistogram(sresult::Simulation; annotateclones = false)

Plot VAF histogram of simulated synthetic data. If `annotateclones = true`, red line will be drawn showing frequency of subclone(s).
"""
function vafhistogram(sresult; annotateclones = false)

    DF = sresult.sampleddata.DF

    if (annotateclones == true) & (sresult.input.numclones > 0)

      xint = sresult.output.clonefreq./2
      xint = sresult.input.cellularity * xint

      p1 = plot(DF, x="VAF", y="freq",
      Guide.xlabel("Allelic Frequency f"),
      Guide.ylabel("Number of Mutations"),
      xintercept = xint,
      Geom.vline(color=colorant"red"),
      Geom.bar,
      Guide.xticks(ticks = collect(0.0:0.2:1.0)),
      Theme(major_label_font_size = 12pt,
      major_label_font = "Arial",
      minor_label_font_size = 10pt,
      minor_label_font = "Arial",
      key_label_font = "Arial",
      key_label_font_size = 10pt,
      default_color = colormap("blues")[80],
      bar_spacing = -0.05cm))

    else

      p1 = plot(DF, x="VAF", y="freq", Geom.bar,
      Guide.xlabel("Allelic Frequency f"),
      Guide.ylabel("Number of Mutations"),
      Guide.xticks(ticks = collect(0.0:0.2:1.0)),
      Theme(major_label_font_size = 12pt,
      major_label_font = "Arial",
      minor_label_font_size = 10pt,
      minor_label_font = "Arial",
      key_label_font = "Arial",
      key_label_font_size = 10pt,
      default_color = colormap("blues")[80],
      bar_spacing = -0.05cm))
    end

    return p1
end

function vafhistogram(sresult::SimulationM; annotateclones = false)

    DF = sresult.sampleddata.DF

    p1 = plot(DF, x="VAF", y="freq", Geom.bar,
    Guide.xlabel("Allelic Frequency f"),
    Guide.ylabel("Number of Mutations"),
    Guide.xticks(ticks = collect(0.0:0.2:1.0)),
    Theme(major_label_font_size = 12pt,
    major_label_font = "Arial",
    minor_label_font_size = 10pt,
    minor_label_font = "Arial",
    key_label_font = "Arial",
    key_label_font_size = 10pt,
    default_color = colormap("blues")[80],
    bar_spacing = -0.05cm))

    return p1
end

function makelims(fmax)
  func(x) = "1/$(round(1/(x+(1/fmax)), 3))"
end

"""
    cumulativeplot(sresult::Simulation; fmin = 0.1, fmax = 0.3)

Plot cumulative distribution and fit for 1/f model. See Williams. et al 2016.
"""
function cumulativeplot(sresult; fmin = 0.1, fmax = 0.3)

    AD = cumulativedist(sresult, fmin = fmin, fmax = fmax)
    DF1 = AD.DF
    DF = getsummary(sresult)

    muin = round(DF[:mu][1], 1)
    mufit = round(DF[:muout][1], 1)
    rsq = round(DF[:rsq][1], 3)

    minrange = minimum(DF1[:v])
    maxrange = maximum(DF1[:v])

    func = makelims(maxrange)

    p2=plot(DF1,

    layer(x = "invf", y = "prediction",Geom.line,
    Theme(default_color = default_color=colormap("reds")[80],
    line_width = 0.08cm)),

    layer(x = "invf", y = "cumsum", Geom.line,
    Theme(line_width = 0.1cm,
    default_color = colormap("blues")[80])),
    Scale.x_continuous(minvalue = minimum(DF1[:invf]),
    maxvalue = maximum(DF1[:invf]), labels = func),
    Scale.y_continuous(minvalue = 0,
    maxvalue = maximum(DF1[:cumsum])),

    Theme(major_label_font_size = 12pt,
    major_label_font = "Arial",
    minor_label_font_size = 10pt,
    minor_label_font = "Arial",
    key_label_font = "Arial",
    key_label_font_size = 10pt),
    Guide.manual_color_key("",
    ["Simulated Data", "Model Fit"],
    [color(colormap("blues")[80]), color(colormap("reds")[80])]),
    Guide.annotation(compose(context(),text(0, maximum(DF1[:cumsum]), "R<sup>2</sup> = $(rsq)"))),
    Guide.annotation(compose(context(),text(0, 0.9*maximum(DF1[:cumsum]), "μ<sub>in</sub> = $(muin)"))),
    Guide.annotation(compose(context(),text(0, 0.8*maximum(DF1[:cumsum]), "μ<sub>fit</sub> = $(mufit)"))),
    Guide.xlabel("Inverse Allelic Frequency 1/f"),
    Guide.ylabel("Cumulative # of Mutations M(f)"),
    Guide.xticks(ticks = [1/maxrange - 1/maxrange, 1/minrange - 1/maxrange]))

end

function selection(λ, f, tend, t1)
    #define the equation for selection as above
    s = (λ .* t1 + log.(f ./ (1 - f))) ./ (λ .* (tend - t1))
    return s
end


function selection2clone(λ, f1, f2, tend, t1, t2)
    #define the equation for selection as above

    s1 = zeros(Float64, length(f1))
    s2 = zeros(Float64, length(f1))

    for i in 1:length(f1)
      if (f2[i] + f1[i]) < 1.0
        s1[i] = (λ .* t1[i] + log.(f1[i] ./ (1 - f1[i] - f2[i]))) ./ (λ .* (tend[i] - t1[i]))
        s2[i] = (λ .* t2[i] + log.(f2[i] ./ (1 - f1[i] - f2[i]))) ./ (λ .* (tend[i] - t2[i]))
      else
        s1[i] = (λ .* t1[i] + log.((f1[i] - f2[i]) ./ (1 - f1[i]))) ./ (λ .* (tend[i] - t1[i]))
        s2[i] = (λ .* t2[i] + log.(f2[i] ./ (1 - f1[i]))) ./ (λ .* (tend[i] - t2[i]))
      end
    end

    return s1, s2
end
