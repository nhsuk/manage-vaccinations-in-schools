# frozen_string_literal: true

require "faker"

# Inspired by https://github.com/joke2k/faker/blob/master/faker/providers/address/en_GB/__init__.py

module Faker
  class Address
    class << self
      POSTAL_ZONES_ONE_CHAR = %w[B E G L M N S W].freeze

      POSTAL_ZONES_TWO_CHARS = %w[
        AB
        AL
        BA
        BB
        BD
        BH
        BL
        BN
        BR
        BS
        BT
        CA
        CB
        CF
        CH
        CM
        CO
        CR
        CT
        CV
        CW
        DA
        DD
        DE
        DG
        DH
        DL
        DN
        DT
        DY
        EC
        EH
        EN
        EX
        FK
        FY
        GL
        GY
        GU
        HA
        HD
        HG
        HP
        HR
        HS
        HU
        HX
        IG
        IM
        IP
        IV
        JE
        KA
        KT
        KW
        KY
        LA
        LD
        LE
        LL
        LN
        LS
        LU
        ME
        MK
        ML
        NE
        NG
        NN
        NP
        NR
        NW
        OL
        OX
        PA
        PE
        PH
        PL
        PO
        PR
        RG
        RH
        RM
        SA
        SE
        SG
        SK
        SL
        SM
        SN
        SO
        SP
        SR
        SS
        ST
        SW
        SY
        TA
        TD
        TF
        TN
        TQ
        TR
        TS
        TW
        UB
        WA
        WC
        WD
        WF
        WN
        WR
        WS
        WV
        YO
        ZE
      ].freeze

      POSTCODE_FORMATS = [
        "AN NEE",
        "ANN NEE",
        "PN NEE",
        "PNN NEE",
        "ANC NEE",
        "PND NEE"
      ].freeze

      POSTCODE_PLACEHOLDERS = {
        " " => [" "],
        "N" => (0..9).map(&:to_s),
        "A" => POSTAL_ZONES_ONE_CHAR,
        "B" => "ABCDEFGHKLMNOPQRSTUVWXY".chars,
        "C" => "ABCDEFGHJKSTUW".chars,
        "D" => "ABEHMNPRVWXY".chars,
        "E" => "ABDEFGHJLNPQRSTUWXYZ".chars,
        "P" => POSTAL_ZONES_TWO_CHARS
      }.freeze

      def uk_postcode
        POSTCODE_FORMATS
          .sample
          .chars
          .map { |placeholder| POSTCODE_PLACEHOLDERS.fetch(placeholder).sample }
          .join
      end
    end
  end
end
