module Sufia
  module BatchControllerBehavior
    extend ActiveSupport::Concern
    require "rubygems"
    require "json"
    include Hydra::Controller::ControllerBehavior
    

    included do
      layout "sufia-one-column"

      before_action :has_access?
      ActiveSupport::Deprecation.deprecate_methods(BatchController, :initialize_fields)
      class_attribute :edit_form_class
      self.edit_form_class = Sufia::Forms::BatchEditForm
    end

    def edit
      @batch = Batch.find_or_create(params[:id])
      @form = edit_form
    end

    def update
      authenticate_user!
      @batch = Batch.find_or_create(params[:id])
      @batch.status = ["processing"]
      @batch.save
      file_attributes = edit_form_class.model_attributes(params[:generic_file])
      Sufia.queue.push(BatchUpdateJob.new(current_user.user_key, params[:id], params[:title], file_attributes, params[:visibility]))
      flash[:notice] = 'Your files are being processed by ' + t('sufia.product_name') + ' in the background. The metadata and access controls you specified are being applied. Files will be marked <span class="label label-danger" title="Private">Private</span> until this process is complete (shouldn\'t take too long, hang in there!). You may need to refresh your dashboard to see these updates.'
      if uploading_on_behalf_of? @batch
        redirect_to sufia.dashboard_shares_path
      else
        redirect_to sufia.dashboard_files_path
      end
    end

    protected

      def edit_form
        generic_file = ::GenericFile.new(creator: [current_user.name], title: @batch.generic_files.map(&:label))

	jsonString = @batch.generic_files.map(&:abstract).first.first.to_s
	if (jsonString.size > 5)	
	  my_json = JSON.parse(jsonString, symbolize_names: true)
	  generic_file.creator << if my_json[:creato].empty? then "" else my_json[:creato] end
  	  generic_file.description << if my_json[:descri].empty? then "" else my_json[:descri] end
  	  generic_file.description << if my_json[:relati].empty? then "" else my_json[:relati] end
  	  generic_file.description << @batch.generic_files.map(&:education_level)
	  generic_file.identifier << if my_json[:identi].empty? then "" else my_json[:identi] end
	  generic_file.language << if my_json[:langua].empty? then "" else my_json[:langua] end
	  generic_file.subject << if my_json[:subjec].empty? then "" else my_json[:subjec] end
	  generic_file.date_created << if my_json[:date].empty? then "" else my_json[:date] end
	  generic_file.contributor << if my_json[:contri].empty? then "" else my_json[:contri] end
	  generic_file.tag << if my_json[:genre].empty? then "" else my_json[:genre] end
 	  generic_file.publisher << if my_json[:publis].empty? then "" else my_json[:publis] end
	  generic_file.rights << if my_json[:rights].empty? then "" else my_json[:rights] end
	end
	edit_form_class.new(generic_file)
      end

      # override this method if you need to initialize more complex RDF assertions (b-nodes)
      def initialize_fields(file)
        file.initialize_fields
      end

      def uploading_on_behalf_of?(batch)
        file = batch.generic_files.first
        return false if file.nil? || file.on_behalf_of.blank?
        current_user.user_key != file.on_behalf_of
      end
  end
end
