# frozen_string_literal: true

require "rails_helper"

# Guards against N+1 queries on the pages that list packed items, boxes and pallets.
# Each example renders a page, adds more rows of every kind that page lists, and
# renders it again. The number of queries must stay the same no matter how many rows
# there are.
describe "Query counts", type: :request do
  let(:user) { create :user, status: "Active", role: "Admin" }
  let(:shipment) { create :shipment }
  let(:container) { create :container, shipment: shipment }
  let(:pallet) { create :pallet, container: container }
  let(:box) { create :box, pallet: pallet, container: nil }

  before do
    skip_webpacker_assets
    sign_in user
  end

  def packed_item(**parents)
    create :packed_item, { box: nil, pallet: nil, container: nil, shipment: nil, quantity: 1 }.merge(parents)
  end

  def pallet_with_contents(container)
    create(:pallet, container: container).tap do |p|
      packed_item(pallet: p)
      packed_item(box: create(:box, pallet: p, container: nil))
    end
  end

  def container_box_with_item(container)
    create(:box, container: container, pallet: nil).tap { |b| packed_item(box: b) }
  end

  # Unassigned staged and warehoused records, shown in the "Quick Add" lists.
  def add_unassigned_records
    %w[Staged Warehoused].each do |status|
      packed_item(status: status)
      create :box, pallet: nil, container: nil, status: status
      staged_pallet = create :pallet, container: nil, status: status
      create :box, pallet: staged_pallet, container: nil
    end
  end

  # Renders `path` before and after `add_rows` runs, and expects both renders to
  # run the same number of queries.
  def expect_constant_queries(path, add_rows)
    add_rows.call
    baseline = queries_for_get(path)

    3.times { add_rows.call }
    expect(queries_for_get(path)).to eq(baseline),
      "expected #{path} to run #{baseline} queries regardless of row count, but it ran more after adding rows"
  end

  it "does not N+1 on the shipment page" do
    expect_constant_queries("/shipments/#{shipment.id}", lambda {
      packed_item(container: container)
      pallet_with_contents(container)
      container_box_with_item(container)
      add_unassigned_records
    })
  end

  it "does not N+1 on the container page" do
    expect_constant_queries("/containers/#{container.id}", lambda {
      packed_item(container: container)
      pallet_with_contents(container)
      container_box_with_item(container)
      add_unassigned_records
    })
  end

  it "does not N+1 on the pallet page" do
    expect_constant_queries("/pallets/#{pallet.id}", lambda {
      packed_item(pallet: pallet)
      packed_item(box: create(:box, pallet: pallet, container: nil))
      add_unassigned_records
    })
  end

  it "does not N+1 on the box page" do
    expect_constant_queries("/boxes/#{box.id}", lambda {
      packed_item(box: box)
      add_unassigned_records
    })
  end

  it "does not N+1 on the boxes index" do
    expect_constant_queries("/boxes", lambda {
      create :box, pallet: create(:pallet, container: create(:container, shipment: create(:shipment))), container: nil
      create :box, container: create(:container, shipment: create(:shipment)), pallet: nil
    })
  end

  it "does not N+1 on the staged boxes index" do
    expect_constant_queries("/boxes?display=staged", -> { add_unassigned_records })
  end

  it "does not N+1 on the pallets index" do
    expect_constant_queries("/pallets", lambda {
      pallet_with_contents(create(:container, shipment: create(:shipment)))
    })
  end

  it "does not N+1 on the containers index" do
    expect_constant_queries("/containers", -> { create :container, shipment: create(:shipment) })
  end
end
