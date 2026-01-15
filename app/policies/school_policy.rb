# frozen_string_literal: true

class SchoolPolicy < LocationPolicy
  def import? = team.has_poc_only_access?

  def patients? = team.has_poc_only_access?

  def sessions? = team.has_poc_only_access?

  def new? = team.has_poc_only_access?

  def create? = team.has_poc_only_access?
end
