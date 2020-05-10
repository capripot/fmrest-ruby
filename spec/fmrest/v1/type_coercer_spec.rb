require "spec_helper"

RSpec.describe FmRest::V1::TypeCoercer do
  let(:hostname) { "stub" }

  let(:coerce_dates) { true }

  let(:date_format) { nil }

  let(:config) do
    {
      coerce_dates: coerce_dates,
      date_format:  date_format
    }
  end

  let :faraday do
    Faraday.new("https://#{hostname}") do |conn|
      conn.use described_class, config
      conn.response :json
      conn.adapter Faraday.default_adapter
    end
  end

  describe "#call" do
    let(:date_field) { "04/22/2020" }
    let(:timestamp_field) { "04/22/2020 11:11:11" }
    let(:time_field) { "11:11:11" }

    before do
      stub_request(:get, "https://#{hostname}/").to_return_fm(
        data: [{
          fieldData: {
            someDateField: date_field,
            someTimestampField: timestamp_field,
            someTimeField: time_field,
            someNonDateField: "Hi I'm regular text"
          },

          portalData: {
            portal1: [{
              "PortalOne::someDate" => date_field
            }],
            portal2: [{
              "PortalTwo::someDate" => date_field
            }]
          }
        }]
      )
    end

    context "with coerce_dates set to true" do
      it "coerces date fields to FmRest::StringDate" do
        response = faraday.get("/")
        date_field = response.body.dig("response", "data", 0, "fieldData", "someDateField")
        expect(date_field.class).to eq(FmRest::StringDate)
        expect(date_field).to eq(Date.civil(2020, 4, 22))
      end

      it "coerces date fields in portal data" do
        response = faraday.get("/")

        date_field_1 = response.body.dig("response", "data", 0, "portalData", "portal1", 0, "PortalOne::someDate")
        expect(date_field_1.class).to eq(FmRest::StringDate)

        date_field_2 = response.body.dig("response", "data", 0, "portalData", "portal2", 0, "PortalTwo::someDate")
        expect(date_field_2.class).to eq(FmRest::StringDate)
      end

      it "coerces timestamp fields to FmRest::StringDateTime" do
        response = faraday.get("/")
        date_field = response.body.dig("response", "data", 0, "fieldData", "someTimestampField")
        expect(date_field).to be_a(FmRest::StringDateTime)
        expect(date_field).to eq(DateTime.civil(2020, 4, 22, 11, 11, 11))
      end

      it "coerces time fields to FmRest::StringDateTime set to the zero Julian Day" do
        response = faraday.get("/")
        date_field = response.body.dig("response", "data", 0, "fieldData", "someTimeField")
        expect(date_field).to be_a(FmRest::StringDateTime)
        expect(date_field).to eq(DateTime.civil(-4712, 1, 1, 11, 11, 11))
      end

      it "doesn't coerce non-date fields" do
        response = faraday.get("/")
        expect(response.body.dig("response", "data", 0, "fieldData", "someNonDateField").class).to eq(String)
      end

      context "with a custom date format given in options" do
        let(:date_format) { "yyyy-MM-dd" }
        let(:date_field) { "2020-06-19" }

        it "correctly coerces date fields to FmRest::StringDate" do
          response = faraday.get("/")
          expect(response.body.dig("response", "data", 0, "fieldData", "someDateField")).to eq(Date.civil(2020, 6, 19))
        end
      end
    end

    context "with coerce_dates set to false" do
      let(:coerce_dates) { false }

      it "doesn't coerce date fields to FmRest::StringDate" do
        response = faraday.get("/")
        expect(response.body.dig("response", "data", 0, "fieldData", "someDateField").class).to eq(String)
      end
    end
  end
end
