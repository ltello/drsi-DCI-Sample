require 'model_spec_helper'

describe Item do

  context "Checking Fields" do
    [:name].each do |fieldname|
      it("When blank?, it adds an error on #{fieldname}") {should validate_presence_of(fieldname)}
    end
  end


  context "Creating a new item" do
    let(:item) {Item.create(name: 'item1', description: 'item1 description')}

    it "When given good params, a new item is created and persisted with right fields values:" do
      ->{Item.create(name: 'Item1')}.should change(Item, :count).by(1)
    end
    it "... #name,"            do item.name.should        == 'item1'             end
    it "... and #description." do item.description.should == 'item1 description' end
  end

end
