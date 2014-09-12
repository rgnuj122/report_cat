require 'spec_helper'

include ReportCat::Core

module ReportCat::Core

  describe Report do

    include SetupReports

    before( :each ) do
      @name = :test
      @report = Report.new( :name => @name )
    end

    #############################################################################
    # initialize

    describe '#initialize' do

      it 'initializes accessor values' do
        @report.name.should eql( @name )
        @report.params.should eql( [] )
        @report.columns.should eql( [] )
        @report.rows.should eql( [] )
        @report.charts.should eql( [] )
      end

      it 'accepts arrays' do
        array = [ 'a', 'b' ]

        report = Report.new(
            :from => array,
            :joins => array,
            :where => array,
            :group_by => array,
            :order_by => array
        )

        expect( report.from ).to eql( 'a,b' )
        expect( report.joins ).to eql( 'a b' )
        expect( report.where ).to eql( 'a and b' )
        expect( report.group_by ).to eql( 'a,b' )
        expect( report.order_by ).to eql( 'a,b' )
      end

    end

    #############################################################################
    # accept_array

    describe '#accept_array' do

      it 'joins arrays with the separator' do
        expected = '1,2,3'
        expect( @report.accept_array( [ '1', '2', '3' ], ',' ) ).to eql( expected )
      end

      it 'returns non arrays' do
        expect( @report.accept_array( 1, ',' ) ).to eql( 1 )
        expect( @report.accept_array( :foo, ',' ) ).to eql( :foo )
      end

    end

    #############################################################################
    # add_chart

    describe '#add_chart' do

      it 'adds a chart' do
        name = :i_like_pie
        type = :pie
        label = :label
        values = [ :value_1, :value_2 ]
        options = { :sweet => true }

        @report.charts.should be_empty
        @report.add_chart( name, type, label, values, options )
        @report.charts.size.should eql( 1 )

        chart = @report.charts.first

        chart.should be_an_instance_of( Chart )
        chart.name.should eql( name )
        chart.type.should eql( type )
        chart.label.should eql( label )
        chart.values.should eql( values )
        chart.options.should eql( options )
      end

    end

    #############################################################################
    # add_column

    describe '#add_column' do

      it 'adds a column' do
        name = :foo
        type = :integer
        options = { :sql => 'count( 1 )' }

        @report.columns.should be_empty
        @report.add_column( name, type, options )
        @report.columns.size.should eql( 1 )

        column = @report.columns.first
        column.name.should eql( name )
        column.type.should eql( type )
        column.options.should eql( options )
      end

    end

    #############################################################################
    # add_param

    describe '#add_param' do

      it 'adds a param' do
        name = :foo
        type = :integer

        @report.params.should be_empty
        @report.add_param( name, type )
        @report.params.size.should eql( 1 )

        param = @report.params.first
        param.should be_an_instance_of( Param )
        param.name.should eql( name )
        param.type.should eql( type )
      end

    end

    #############################################################################
    # column

    describe '#column' do

      before( :each ) do
        setup_reports
      end

      it 'returns the named column' do
        @report.columns.size.should > 1
        @report.columns.each_index do |i|
          column = @report.columns[ i ]
          @report.column( column.name ).should eql( column )
        end

      end


      it 'returns nil if it is unable to find the column' do
        @report.column( :does_not_exist ).should be_nil
      end

    end


    #############################################################################
    # column_index

    describe '#column_index' do

      before( :each ) do
        setup_reports
      end

      it 'returns the index of the named column' do
        @report.columns.size.should > 1
        @report.columns.each_index do |i|
          column = @report.columns[ i ]
          @report.column_index( column.name ).should eql( i )
        end

      end


      it 'returns nil if it is unable to find the column' do
        @report.column_index( :does_not_exist ).should be_nil
      end

    end


    #############################################################################
    # generate

    describe '#generate' do

      before( :each ) do
        setup_reports
        @report.stub( :query ).and_return( nil )
      end

      it 'applies passed in options to params of the same name' do
        @report.param( :text_field_test ).value.should be_nil
        @report.generate( :text_field_test => 'foobar' )
        @report.param( :text_field_test ).value.should eql( 'foobar' )
      end

    end

    #############################################################################
    # param

    describe '#param' do

      before( :each ) do
        @param = @report.add_param( :foo, :integer )
      end

      it 'finds a parameter by name' do
        @report.param( :foo ).should be( @param )
      end

      it 'returns nil if it can not find it' do
        @report.param( :bar ).should be_nil
      end

    end

    #############################################################################
    # to_csv

    describe '#to_csv' do

      before( :each ) do
        setup_reports
        @report.stub( :query ).and_return( nil )
      end

      it 'generates CSV' do
        @report.to_csv.should eql_file( 'spec/data/lib/report.csv' )
      end

    end

    #############################################################################
    # attributes

    describe '#attributes' do

      before( :each ) do
        setup_reports
      end

      it 'includes the name as both name and id' do
        expect( @report.attributes[ :id ] ).to eql( @report.name )
        expect( @report.attributes[ :name ] ).to eql( @report.name )
      end

      it 'includes back if defined' do
        back = @report.attributes
        expect( @report.attributes.has_key?( :back ) ).to be( false )
        @report.back = back
        expect( @report.attributes[ :back ] ).to eql( back )
      end

      it 'returns a hash of param names to values' do
        @report.params.each do |param|
          expect( @report.attributes[ param.name ] ).to eql( param.value )
        end
      end

    end

    #############################################################################
    # query

    describe '#query' do

      before( :each ) do
        setup_reports
       end

      it 'initializes rows' do
        @report.rows << []
        @report.rows.size.should > 0

        @report.should_receive( :to_sql ).and_return( nil )
        ActiveRecord::Base.connection.stub( :execute ).and_return( nil )

        @report.send( :query )
        @report.rows.size.should eql( 0 )
      end

      it 'executes SQL against ActiveRecord' do
        sql = 'foobar
'
        @report.should_receive( :to_sql ).and_return( sql )
        ActiveRecord::Base.connection.should_receive( :execute ).with( sql ).and_return( nil )
        @report.send( :query )
      end

      it 'tolerates nil results from ActiveRecord' do
        @report.should_receive( :to_sql ).and_return( nil )
        ActiveRecord::Base.connection.stub( :execute ).and_return( nil )
        @report.send( :query )
      end

      it 'populates rows with the results of the query' do
        results = [ [1], [2] ]

        @report.should_receive( :to_sql ).and_return( nil )
        ActiveRecord::Base.connection.stub( :execute ).and_return( results )
        @report.send( :query )
        @report.rows.size.should eql( results.size )
        results.each_index { |i| @report.rows[ i ].should eql( results[ i ] ) }
      end

      it 'post processes each column' do
        ActiveRecord::Base.connection.stub( :execute ).and_return( [] )

        @report.columns.each { |c| c.should_receive( :post_process ).with( @report ) }
        @report.send( :query )
      end

    end

    #############################################################################
    # to_sql

    describe '#to_sql' do

      before( :each ) do
        setup_reports
        @report.stub( :query ).and_return( nil )
      end

      it 'generates SQL' do
        @report.send( :to_sql ).should eql_file( 'spec/data/lib/report.sql' )
      end

    end

  end

end
