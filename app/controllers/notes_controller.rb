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

    the_note.destroy

    redirect_to("/notes", { :notice => "Note deleted successfully." } )
  end
end
