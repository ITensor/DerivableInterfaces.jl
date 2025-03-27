using DerivableInterfaces: DerivableInterfaces
using Documenter: Documenter, DocMeta, deploydocs, makedocs

DocMeta.setdocmeta!(
  DerivableInterfaces, :DocTestSetup, :(using DerivableInterfaces); recursive=true
)

include("make_index.jl")

makedocs(;
  modules=[DerivableInterfaces],
  authors="ITensor developers <support@itensor.org> and contributors",
  sitename="DerivableInterfaces.jl",
  format=Documenter.HTML(;
    canonical="https://itensor.github.io/DerivableInterfaces.jl",
    edit_link="main",
    assets=["assets/favicon.ico", "assets/extras.css"],
  ),
  pages=["Home" => "index.md", "Reference" => "reference.md"],
)

deploydocs(;
  repo="github.com/ITensor/DerivableInterfaces.jl", devbranch="main", push_preview=true
)
