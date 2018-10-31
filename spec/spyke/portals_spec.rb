require "spec_helper"

require "spyke/fixtures/pirates"

RSpec.describe FmData::Spyke::Model::Portals do
  describe ".portal" do
    it "creates a Portal instance association" do
      expect(Ship.new.crew).to be_a(FmData::Spyke::Portal)
    end

    it "finds the associated class based on the given class_name" do
      expect(Ship.new.crew.klass).to be(Pirate)
    end
  end

  describe "loading a record with portal data" do
    before do
      stub_session_login

      stub_request(:get, "https://example.com/fmi/data/v1/databases/TestDB/layouts/Ships/records/1").to_return_fm(
        data: [
          {
            fieldData: {
              name: "De Vliegende Hollander"
            },

            portalData: {
              Pirates: [
                {
                  "Pirates::name": "Hendrick van der Decken",
                  "Pirates::rank": "Captain",
                  recordId: 1
                },

                {
                  "Pirates::name": "Marthijn van het Vriesendijks",
                  "Pirates::rank": "First Officer",
                  recordId: 2
                }
              ]
            },

            modId: 1,
            recordId: 1
          }
        ]
      )
    end

    it "initializes the portal's associated records" do
      ship = Ship.find(1)

      expect(ship.crew.count).to eq(2)
      expect(ship.crew.first).to be_a(Pirate)
      expect(ship.crew.first.name).to eq("Hendrick van der Decken")
      expect(ship.crew.first.rank).to eq("Captain")
    end
  end
end
