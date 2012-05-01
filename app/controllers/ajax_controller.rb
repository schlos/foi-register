class AjaxController < ApplicationController
  def requestors
    if params[:term]
      requestors = Requestor.where("name like '%'||?||'%'", params[:term])
    else
      requestors = Requestor.all
    end
    list = requestors.map do |requestor|
      {
        :id => requestor.id, :label => requestor.to_s, :value => requestor.name,
        :name => requestor.name, :email => requestor.email
      }
    end
    render :json => list
  end

  def lgcs_terms
    if params[:term]
      lgcs_terms = LGCSTerm.where("name like '%'||?||'%'", params[:term])
    else
      lgcs_terms = LGCSTerm.all
    end
    list = lgcs_terms.map do |lgcs_term|
      {
        :id => lgcs_term.id, :value => lgcs_term.to_s,
        :name => lgcs_term.name, :notes => lgcs_term.notes
      }
    end
    render :json => list
  end
end
