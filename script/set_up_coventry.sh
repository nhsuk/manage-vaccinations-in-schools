set -eux

bin/rails db:schema:load

bin/rails vaccines:seed[hpv]
bin/rails schools:import

bin/rails "teams:create_hpv[example@covwarkpt.nhs.uk,Coventry and Warwickshire Partnership NHS Trust,07700 900815,RYG,,]"
bin/rails users:create[nurse.ryg@example.com,nurse.ryg@example.com,Nurse,RYG,RYG]

bin/rails schools:add_to_team[RYG,141939,103751,103760,139292,134269,150498,141376,140958,149424,131574,141992,146436,137209,136126,103747,142960,140366,135335,141104,137272,147346,103750,142339,137225,140248,138023,140961,134970,141008,125790,149577,137781,136587,140354,145575,125773,145200,140654,137771,125794,140371,138644,137767,143707,145019,149580,141277,148398,139936,139468,134464,144764,142881,136595,125777,141836,125764,136986,137079,148828,136158,136459,139937,148243,148554,137597,149916,145224,137172,136622,125774,137770,147345,145470,137766,125805,136963,136991,146697,147432,137302,125788,148429,136907,142202,136510,125787,138767,143905,143634,137235,137236,136786,125775,148362,144633,148032,125781,145486]

# !IMPORTANT! The ODS codes of these clinics are not correct.

bin/rails "clinics:create[Jepson House,4 Manor Court Avenue,Nuneaton,CV11 5HX,CV115HX,RYG]"
bin/rails "clinics:create[Locke House,The Railings Woodside Park,Rugby,CV21 2AW,CV212AW,RYG]"
bin/rails "clinics:create[Woodloes House,Woodloes Avenue South,Warwick,CV34 5XN,CV345XN,RYG]"
bin/rails "clinics:create[Alcester Clinic,Fields Park Drive,Warwickshire,B49 6QR,B496QR,RYG]"
bin/rails "clinics:create[City Of Coventry Health Centre,2 Stoney Stanton Road,Coventry,CV1 4FS,CV14FS,RYG]"
