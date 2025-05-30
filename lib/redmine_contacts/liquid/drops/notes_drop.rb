module RedmineContacts
  module Liquid
    module Drops

class NotesDrop < ::Liquid::Drop

  def initialize(notes)
    @notes = notes
  end

  def before_method(id)
    note = @notes.where(:id => id).first || Note.new
    NoteDrop.new note
  end

  def all
    @all ||= @notes.map do |note|
      NoteDrop.new note
    end
  end

  def visible
    @visible ||= @notes.visible.map do |note|
      NoteDrop.new note
    end
  end

  def each(&block)
    all.each(&block)
  end

end


class NoteDrop < ::Liquid::Drop

  delegate :id, :subject, :content, :type_id, :to => :@note

  def initialize(note)
    @note = note
  end
  def custom_field_values
    @note.custom_field_values
  end

end

    end
  end
end