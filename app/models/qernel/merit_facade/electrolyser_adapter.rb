# waarom heeft hij een volatile profiel?

# wat hij voornameljk doet is ervoor zorgen dat
# het curtailment goed gaat

# het lijkt me sterk dat hij een volatile profile heeft
# hij heeft toch gewoon de ouput_e_curve van die andere?
# nee dat klopt ook niet
# want er is al gecurtaild

# jeetje wat een ingewikkelde modellering

# kan hij niet gewoon 1 node zijn die zowel meedoet in
# merit als hydrogen??

# nee want er komt geen e in!

# ahah volatile doet niet eens mee in merit als producer natuurlijk

# ok dus eigenlijk het enige wat hij doet is achteraf na alle
# berekeningen kijken of hij inderdaad alles heeft gebruikt wat hij kon!


# dus echt gewoon letterlijk die dinges overzetten en ipv demand pahse doen
# we het in de injects!

# nee nee wat moeten we fixen dan??
# waarom stroomt het niet al goed?

# OK: hij kan dus wellicht niet voldoen aan zijn input curve??
# hoe gaat dat nu?


# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Electrolysers are a special-case producer whose load profile is based on
    # the electricity output by another node.
    #
    # The electricity node is expected to be the only input to the electrolyser,
    # and will have a second electricity output to a curtailment node.
    #
    #   [ Electrolyser ]  <-
    #                         [ Electricity Producer ]
    #   [ Curtailment ]  <--
    #
    # The load profile is based on the electricity profile of the input
    # producer, limited by the efficiency and capacity of the electrolyser. From
    # the resulting profile, the demand and full load hours can be calculated,
    # and the share of curtailment updated.
    class ElectrolyserAdapter < AlwaysOnAdapter

    end
  end
end
