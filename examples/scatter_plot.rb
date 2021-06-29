require "charty"
require "datasets"
require "matplotlib"

Charty::Backends.use(:pyplot)
Matplotlib.use(:agg)

penguins = Datasets::Penguins.new

Charty.scatter_plot(data: penguins, x: :body_mass_g, y: :flipper_length_mm)
      .save("penguins_body_mass_g_flipper_length_mm_scatter_plot.png")

Charty.scatter_plot(data: penguins, x: :body_mass_g, y: :flipper_length_mm, color: :species)
      .save("penguins_body_mass_g_flipper_length_mm_species_scatter_plot.png")

Charty.scatter_plot(data: penguins, x: :body_mass_g, y: :flipper_length_mm, color: :species, style: :sex)
      .save("penguins_body_mass_g_flipper_length_mm_species_sex_scatter_plot.png")
