# frozen_string_literal: true

require "rails_helper"

describe SerialNumberExtraction do
  describe ".propose" do
    {
      "Hospital Bed, Stryker, FL28C, Serial #R30922" => ["R30922", "Hospital Bed, Stryker, FL28C"],
      "Battery (78VPG) - Serial #73834" => ["73834", "Battery (78VPG)"],
      "Laptop, Toshiba S855 - S/N YC17212BQ / KBNF ID 10076" => ["YC17212BQ", "Laptop, Toshiba S855, KBNF ID 10076"],
      "Chair, Lumex, Model 577RG427 (S/N ? 717076051859), Date Code: 0732" =>
        ["717076051859", "Chair, Lumex, Model 577RG427, Date Code: 0732"],
      "Hill-Rom Total Care; Model: P1900L00627; S/N: I269AM4092" => ["I269AM4092", "Hill-Rom Total Care; Model: P1900L00627"],
      "Ultrasound Machine, Philips Model iU22, S/N B0G 23Q / KBNF ID 10084" =>
        ["B0G 23Q", "Ultrasound Machine, Philips Model iU22, KBNF ID 10084"],
      "Stryker, (No Model #), S/N 0206 043380" => ["0206 043380", "Stryker, (No Model #)"]
    }.each do |text, (serial, rest)|
      it "takes #{serial.inspect} out of #{text.inspect}" do
        expect(described_class.propose(text)).to eq(serial: serial, rest: rest)
      end
    end

    {
      "Zeiss OMPI NC4, S/N" => "marker with no value",
      "Cautery Machine, Valleylab, S/N illegible, KBNF ID 10254" => "not a serial: illegible",
      "Backboard, Emergency (Ferno) - No Serial Number" => "says there's no serial",
      "Heine EN90 (S/N 0/1109) and EN90 Duo S/N 0/1314" => "2 serial markers",
      "Birthing Bed, Stryker, S/N 0401 062085 for Redemption Hospital" => "serial looks long (35 chars)"
    }.each do |text, reason|
      it "leaves #{text.inspect} for a person (#{reason})" do
        expect(described_class.propose(text)).to eq(reason: reason)
      end
    end

    it "ignores text without a serial" do
      expect(described_class.propose("Gauze Pad, Sterile")).to be_nil
    end
  end

  describe ".plan" do
    it "proposes moving a serial from the name, with the new name" do
      item = create :item, object: "Hospital Bed, Serial #R30922", brand: "Stryker"

      change = described_class.plan.sole
      expect([change.status, change.field, change.serial, change.after]).to eq([:auto, :object, "R30922", "Hospital Bed"])
      expect(change.new_name).to eq("Stryker Hospital Bed S/N R30922")
      expect(change.item).to eq(item)
    end

    it "sends anything that would clash with another item's name to review" do
      create :item, object: "Hospital Bed", serial_number: "R30922"
      create :item, object: "Hospital Bed, Serial #R30922"

      change = described_class.plan.find(&:before)
      expect([change.status, change.reason]).to eq([:review, "new name would duplicate another item"])
    end

    it "leaves serials mentioned only in notes alone" do
      create :item, object: "Monitor", notes: "S/N on the back plate"

      expect(described_class.plan.sole.status).to eq(:skip)
    end
  end

  describe ".apply! and .restore!" do
    let(:backup) { Rails.root.join("tmp/serial_number_backup-spec-#{SecureRandom.hex(4)}.csv").to_s }
    let!(:bed) { create :item, object: "Hospital Bed, Serial #R30922", brand: "Stryker" }
    let!(:unclear) { create :item, object: "Zeiss OMPI NC4, S/N" }

    after { FileUtils.rm_f(backup) }

    it "makes the automatic changes, backs up the old values, and restores them exactly" do
      before = bed.slice(:brand, :object, :serial_number, :generated_name)

      applied, skipped = described_class.apply!(described_class.plan, backup)
      expect([applied, skipped]).to eq([1, 0])
      bed.reload
      expect([bed.object, bed.serial_number, bed.generated_name]).to eq(["Hospital Bed", "R30922", "Stryker Hospital Bed S/N R30922"])
      expect(unclear.reload.serial_number).to be_nil
      expect(CSV.read(backup, headers: true).map { |row| row["id"].to_i }).to eq([bed.id])

      expect(described_class.restore!(backup)).to eq(1)
      expect(bed.reload.slice(:brand, :object, :serial_number, :generated_name)).to eq(before)
    end

    it "skips an item edited after the plan was made" do
      changes = described_class.plan
      bed.update!(object: "Hospital Bed (renamed), Serial #R30922")

      expect(described_class.apply!(changes, backup)).to eq([0, 1])
      expect(bed.reload.serial_number).to be_nil
    end

    it "changes nothing if any item fails to save" do
      other = create :item, object: "Battery - Serial #73834"
      changes = described_class.plan
      create :item, object: "Battery", serial_number: "73834" # makes the battery's new name a duplicate

      expect { described_class.apply!(changes, backup) }.to raise_error(ActiveRecord::RecordInvalid)
      expect([bed.reload.serial_number, other.reload.serial_number]).to eq([nil, nil])
    end
  end
end
