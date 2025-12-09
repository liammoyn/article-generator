class NotesController < ApplicationController
  def index
    matching_notes = Note.all

    @list_of_notes = matching_notes.order({ :created_at => :desc })

    render({ :template => "note_templates/index" })
  end

  def show
    the_id = params.fetch("path_id")

    matching_notes = Note.where({ :id => the_id })

    @the_note = matching_notes.at(0)

    render({ :template => "note_templates/show" })
  end

  def file
    the_note = Note.new
    the_note.topic_id = params.fetch("query_topic_id")

    uploaded = params[:query_file]
    if uploaded.present?
      allowed = ["application/pdf", "text/plain"]
      content_type = uploaded.content_type

      unless allowed.include?(content_type)
        redirect_back(:fallback_location => "/", :alert => "Only PDF or TXT files are allowed") and return
      end

      the_note.name = uploaded.original_filename

      if content_type == "text/plain"
        begin
          # Read the uploaded tempfile contents into the note's content
          raw = uploaded.read
          raw = raw.force_encoding("UTF-8") unless raw.encoding.name == "UTF-8"
          the_note.content = raw
        rescue => e
          redirect_back(:fallback_location => "/", :alert => "Unable to read text file: #{e.message}") and return
        ensure
          # rewind in case something else expects the tempfile position
          uploaded.rewind if uploaded.respond_to?(:rewind)
        end
      else
        # For PDFs, attach the file to Active Storage
        the_note.file.attach(uploaded)
      end
    end

    if the_note.valid?
      the_note.save
      redirect_to("/topics/#{the_note.topic_id}", { :note => "Note created successfully" } )
    else
      redirect_back(:fallback_location => "/", :alert => the_note.errors.full_messages.to_sentence)
    end
  end

  def create
    the_note = Note.new
    the_note.content = params.fetch("query_content")
    the_note.topic_id = params.fetch("query_topic_id")

    if the_note.valid?
      the_note.save
      redirect_to("/topics/#{the_note.topic_id}", { :note => "Note created successfully" } )
    else
      redirect_back(:fallback_location => "/", :alert => the_note.errors.full_messages.to_sentence)
    end
  end

  def update
    the_id = params.fetch("path_id")
    the_note = Note.where({ :id => the_id }).at(0)

    the_note.content = params.fetch("query_content")
    the_note.topic_id = params.fetch("query_topic_id")

    if the_note.valid?
      the_note.save
      redirect_to("/notes/#{the_note.id}", { :notice => "Note updated successfully." } )
    else
      redirect_to("/notes/#{the_note.id}", { :alert => the_note.errors.full_messages.to_sentence })
    end
  end

  def destroy
    the_id = params.fetch("path_id")
    the_note = Note.where({ :id => the_id }).at(0)

    if the_note.file.present?
      the_note.file.purge
    end

    the_note.destroy

    redirect_to("/topics/#{the_note.topic_id}", { :note => "Note deleted successfully" } )
  end
end
