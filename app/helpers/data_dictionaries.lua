local M = {}

-- US States dictionary
M.states = {{
    code = "AL",
    name = "Alabama"
}, {
    code = "AK",
    name = "Alaska"
}, {
    code = "AZ",
    name = "Arizona"
}, {
    code = "AR",
    name = "Arkansas"
}, {
    code = "CA",
    name = "California"
}, {
    code = "CO",
    name = "Colorado"
}, {
    code = "CT",
    name = "Connecticut"
}, {
    code = "DE",
    name = "Delaware"
}, {
    code = "FL",
    name = "Florida"
}, {
    code = "GA",
    name = "Georgia"
}, {
    code = "HI",
    name = "Hawaii"
}, {
    code = "ID",
    name = "Idaho"
}, {
    code = "IL",
    name = "Illinois"
}, {
    code = "IN",
    name = "Indiana"
}, {
    code = "IA",
    name = "Iowa"
}, {
    code = "KS",
    name = "Kansas"
}, {
    code = "KY",
    name = "Kentucky"
}, {
    code = "LA",
    name = "Louisiana"
}, {
    code = "ME",
    name = "Maine"
}, {
    code = "MD",
    name = "Maryland"
}, {
    code = "MA",
    name = "Massachusetts"
}, {
    code = "MI",
    name = "Michigan"
}, {
    code = "MN",
    name = "Minnesota"
}, {
    code = "MS",
    name = "Mississippi"
}, {
    code = "MO",
    name = "Missouri"
}, {
    code = "MT",
    name = "Montana"
}, {
    code = "NE",
    name = "Nebraska"
}, {
    code = "NV",
    name = "Nevada"
}, {
    code = "NH",
    name = "New Hampshire"
}, {
    code = "NJ",
    name = "New Jersey"
}, {
    code = "NM",
    name = "New Mexico"
}, {
    code = "NY",
    name = "New York"
}, {
    code = "NC",
    name = "North Carolina"
}, {
    code = "ND",
    name = "North Dakota"
}, {
    code = "OH",
    name = "Ohio"
}, {
    code = "OK",
    name = "Oklahoma"
}, {
    code = "OR",
    name = "Oregon"
}, {
    code = "PA",
    name = "Pennsylvania"
}, {
    code = "RI",
    name = "Rhode Island"
}, {
    code = "SC",
    name = "South Carolina"
}, {
    code = "SD",
    name = "South Dakota"
}, {
    code = "TN",
    name = "Tennessee"
}, {
    code = "TX",
    name = "Texas"
}, {
    code = "UT",
    name = "Utah"
}, {
    code = "VT",
    name = "Vermont"
}, {
    code = "VA",
    name = "Virginia"
}, {
    code = "WA",
    name = "Washington"
}, {
    code = "WV",
    name = "West Virginia"
}, {
    code = "WI",
    name = "Wisconsin"
}, {
    code = "WY",
    name = "Wyoming"
}, {
    code = "DC",
    name = "District of Columbia"
}}

-- Vehicle Makes and Models dictionary
M.vehicle_makes = {"Acura", "Audi", "BMW", "Buick", "Cadillac", "Chevrolet", "Chrysler", "Dodge", "Ford", "GMC",
                   "Honda", "Hyundai", "Infiniti", "Jeep", "Kia", "Lexus", "Lincoln", "Mazda", "Mercedes-Benz",
                   "Mitsubishi", "Nissan", "RAM", "Subaru", "Tesla", "Toyota", "Volkswagen", "Volvo"}

-- Popular models by make (can be extended)
M.vehicle_models = {
    ["Acura"] = {"ILX", "Integra", "MDX", "RDX", "TLX", "ZDX"},
    ["Audi"] = {"A3", "A4", "A5", "A6", "A7", "A8", "Q3", "Q5", "Q7", "Q8", "e-tron"},
    ["BMW"] = {"2 Series", "3 Series", "4 Series", "5 Series", "7 Series", "X1", "X3", "X5", "X7", "i4", "iX"},
    ["Buick"] = {"Enclave", "Encore", "Encore GX", "Envision"},
    ["Cadillac"] = {"CT4", "CT5", "Escalade", "Escalade ESV", "XT4", "XT5", "XT6", "LYRIQ"},
    ["Chevrolet"] = {"Blazer", "Camaro", "Colorado", "Corvette", "Equinox", "Malibu", "Silverado 1500",
                     "Silverado 2500HD", "Silverado 3500HD", "Suburban", "Tahoe", "Trailblazer", "Traverse", "Trax"},
    ["Chrysler"] = {"300", "Pacifica", "Voyager"},
    ["Dodge"] = {"Challenger", "Charger", "Durango", "Hornet"},
    ["Ford"] = {"Bronco", "Bronco Sport", "Edge", "Escape", "Expedition", "Explorer", "F-150", "F-250", "F-350",
                "Maverick", "Mustang", "Mustang Mach-E", "Ranger", "Super Duty"},
    ["GMC"] = {"Acadia", "Canyon", "Sierra 1500", "Sierra 2500HD", "Sierra 3500HD", "Terrain", "Yukon", "Yukon XL"},
    ["Honda"] = {"Accord", "Civic", "CR-V", "HR-V", "Odyssey", "Passport", "Pilot", "Ridgeline"},
    ["Hyundai"] = {"Elantra", "Ioniq 5", "Ioniq 6", "Kona", "Palisade", "Santa Fe", "Sonata", "Tucson", "Venue"},
    ["Infiniti"] = {"Q50", "Q60", "QX50", "QX55", "QX60", "QX80"},
    ["Jeep"] = {"Cherokee", "Compass", "Gladiator", "Grand Cherokee", "Grand Wagoneer", "Renegade", "Wagoneer",
                "Wrangler"},
    ["Kia"] = {"Carnival", "EV6", "Forte", "K5", "Niro", "Seltos", "Sorento", "Sportage", "Stinger", "Telluride"},
    ["Lexus"] = {"ES", "GX", "IS", "LC", "LS", "LX", "NX", "RC", "RX", "TX", "UX"},
    ["Lincoln"] = {"Aviator", "Corsair", "Nautilus", "Navigator"},
    ["Mazda"] = {"CX-30", "CX-5", "CX-50", "CX-90", "Mazda3", "Mazda6", "MX-5 Miata"},
    ["Mercedes-Benz"] = {"A-Class", "C-Class", "E-Class", "S-Class", "GLA", "GLB", "GLC", "GLE", "GLS", "EQS"},
    ["Mitsubishi"] = {"Eclipse Cross", "Mirage", "Outlander", "Outlander Sport"},
    ["Nissan"] = {"Altima", "Ariya", "Armada", "Frontier", "Kicks", "Leaf", "Maxima", "Murano", "Pathfinder", "Rogue",
                  "Sentra", "Titan", "Versa", "Z"},
    ["RAM"] = {"1500", "2500", "3500", "ProMaster", "ProMaster City"},
    ["Subaru"] = {"Ascent", "BRZ", "Crosstrek", "Forester", "Impreza", "Legacy", "Outback", "Solterra", "WRX"},
    ["Tesla"] = {"Model 3", "Model S", "Model X", "Model Y"},
    ["Toyota"] = {"4Runner", "Camry", "Corolla", "Crown", "GR86", "GR Supra", "Highlander", "Prius", "RAV4", "Sequoia",
                  "Sienna", "Tacoma", "Tundra", "Venza"},
    ["Volkswagen"] = {"Arteon", "Atlas", "ID.4", "Jetta", "Passat", "Taos", "Tiguan"},
    ["Volvo"] = {"C40", "S60", "S90", "V60", "V90", "XC40", "XC60", "XC90"}
}

return M
