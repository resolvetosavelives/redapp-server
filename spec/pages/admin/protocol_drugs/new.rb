module AdminPage
  module ProtocolDrugs
    class New < ApplicationPage
      NAME = {id: "protocol_drug_name"}.freeze
      PROTOCOL_DRUG_DOSAGE = {id: "protocol_drug_dosage"}.freeze
      RX_NORM_CODE = {id: "protocol_drug_rxnorm_code"}.freeze
      CREATE_PROTOCOL_BUTTON = {css: "input.btn-primary"}.freeze
      PROTOCOL_NAME_HEADING = {css: "h1"}.freeze

      def add_new_protocol_drug(name, dosage, code)
        type(NAME, name)
        type(PROTOCOL_DRUG_DOSAGE, dosage)
        type(RX_NORM_CODE, code)
        click(CREATE_PROTOCOL_BUTTON)
      end
    end
  end
end
