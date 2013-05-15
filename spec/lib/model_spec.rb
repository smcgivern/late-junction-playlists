require './spec/setup'
require './lib/model'

describe 'model_constant' do
  it 'should return the model class / constant from a table name' do
    class Foo < Sequel::Model; end

    model_constant(Foo.table_name).should.equal Foo
  end
end
