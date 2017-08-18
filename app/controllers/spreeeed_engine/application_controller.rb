module SpreeeedEngine
  class ApplicationController < ActionController::Base
    include SpreeeedEngine::UtilityHelper
    include SpreeeedEngine::RoutesHelper

    include DatatableController

    protect_from_forgery with: :exception

    PER_PAGE = 20

    before_action :"authenticate_#{SpreeeedEngine.devise_auth_resource}!", :set_klass, :set_klass_key

    before_action :set_active_record_config, only: [:index, :new, :show, :edit, :create, :update]
    before_action :set_datatables_config, only: [:index, :show]


    def index
      # retrieve the localization of column name
      @datatable_config[@klass_key][:labels] = datatable_labels(
        @klass.new,
        @datatable_config[@klass_key][:cols]
      )

      respond_to do |format|
        format.html # index.html.erb
        format.json {
          # get all sortable datatable columns
          @datatable_config[@klass_key][:sortable_cols] = datatable_sortable_columns(
            @klass,
            @datatable_config[@klass_key][:cols],
            @datatable_config[@klass_key][:default_sortable_cols]
          )

          # get all datatable instances
          per_page  = params[:iDisplayLength] || PER_PAGE
          page      = (params[:iDisplayStart].to_i / per_page.to_i) + 1

          proxy     = datatable_instances_proxy(
            @klass,
            @datatable_config[@klass_key][:searchable_cols],
            @datatable_config[@klass_key][:sortable_cols]
          )
          @instances = datatable_instances(proxy, page, per_page)
          total      = datatable_instances_total(proxy)

          render json: datatable_raws(
                         @instances,
                         @datatable_config[@klass_key][:cols],
                         total
                       )
          }
      end
    end

    def new
      @object = @klass.new

      respond_to do |format|
        format.html # new.html.erb
        # format.json { render json: @object }
      end
    end

    def show
      @object = find_instance

      respond_to do |format|
        format.html # show.html.erb
        # format.json { render json: @object }
      end
    end

    def edit
      @object = find_instance

      respond_to do |format|
        format.html # edit.html.erb
        # format.json { render json: @object }
      end
    end

    def create
      @object = @klass.new(klass_params(@klass))

      respond_to do |format|
        if @object.save
          format.html { redirect_to object_path(@object), notice: "#{@klass.name} was successfully created." }
          # format.html { redirect_to [SpreeeedEngine.namespace.to_sym, @object], notice: "#{@klass.name} was successfully created." }
          # format.json { render json: @object, status: :created, location: @object }
        else
          format.html { render action: 'new' }
          # format.json { render json: @object.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      @object = find_instance

      respond_to do |format|
        _params = klass_params(@klass)
        if @object.update_attributes(_params)
          # format.html { redirect_to [SpreeeedEngine.namespace.to_sym, @object], notice: "#{@klass_name} was successfully updated." }
          format.html { redirect_to object_path(@object), notice: "#{@klass_name} was successfully updated." }
          # format.json { head :no_content }
        else
          format.html { render action: 'edit' }
          # format.json { render json: @object.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @object = find_instance
      @object.destroy

      respond_to do |format|
        # format.html { redirect_to send("#{SpreeeedEngine.namespace}_#{@klass_name.underscore.pluralize}_url") }
        format.html { redirect_to objects_path }
        # format.json { head :no_content }
      end
    end


    private

    def find_instance
      return nil unless params[:id].present?

      if params[:id].to_s.match(/\D/) || ((defined?(FriendlyId) && @klass.respond_to?('friendly')))
        @klass.friendly.find(params[:id])
      else
        @klass.find(params[:id])
      end
    end

    def klass_params(klass)
      nested_params = klass.nested_attrs.collect { |name, class_name|
        {"#{name}_attributes".to_sym => class_name.constantize.editable_attrs + [:id, :_destroy]}
      }
      params.require(klass.name.parameterize.underscore.to_sym).permit(klass.editable_attrs + nested_params)
    end

    def set_klass
      @klass ||= NilClass
    end

    def set_klass_key
      @klass_key = @klass.name.to_sym
    end

    def set_active_record_config
      @active_record_config      ||= {}
      @active_record_config[@klass_key] ||= {}

      if @klass.name == 'NilClass'
        @active_record_config[@klass_key][:displayable_attrs] = []
        @active_record_config[@klass_key][:editable_attrs]    = []
        @active_record_config[@klass_key][:nested_attrs]      = []
        @active_record_config[@klass_key][:hidden_attrs]      = []
        @active_record_config[@klass_key][:creatable]         = false
        @active_record_config[@klass_key][:editable]          = false
        @active_record_config[@klass_key][:deletable]         = false
      else
        @active_record_config[@klass_key][:displayable_attrs] = @klass.displayable_attrs
        @active_record_config[@klass_key][:editable_attrs]    = @klass.editable_attrs
        @active_record_config[@klass_key][:nested_attrs]      = @klass.nested_attrs
        @active_record_config[@klass_key][:hidden_attrs]      = @klass.hidden_attrs
        @active_record_config[@klass_key][:creatable]         = true
        @active_record_config[@klass_key][:editable]          = true
        @active_record_config[@klass_key][:deletable]         = true
      end
    end

    def set_datatables_config
      @datatable_config                                       = {}
      @datatable_config[@klass_key]                           = {}
      @datatable_config[@klass_key][:cols]                    = @klass.datatable_cols
      @datatable_config[@klass_key][:searchable_cols]         = @klass.datatable_searchable_cols
      @datatable_config[@klass_key][:sortable_cols]           = @klass.datatable_sortable_cols
      @datatable_config[@klass_key][:default_sortable_cols]   = @klass.datatable_default_sortable_cols
    end



  end
end
