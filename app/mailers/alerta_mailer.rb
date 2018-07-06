#require 'byebug'

class AlertaMailer < ApplicationMailer
  
  def alerta_proyectofinanciero
    #byebug
    if !ENV['SMTP_MAQ']
      puts "No esta definida variable de ambiente SMTP_MAQ"
      exit 1
    end
    puts "OJO alerta_proyectofinanciero"
    pf_id = params[:proyectofinanciero_id]
    puts "OJO alerta_proyectofinanciero pf_id=#{pf_id}"
    @tiene = params[:tiene]
    puts "OJO alerta_proyectofinanciero tiene=#{@tiene}"
    @cuando = params[:cuando]
    puts "OJO alerta_proyectofinanciero cuando=#{@cuando}"
    @complemento = params[:complemento]
    puts "OJO alerta_proyectofinanciero cuando=#{@cuando}"
    @pf = Cor1440Gen::Proyectofinanciero.find(pf_id)
    return if !@pf
    puts "pf.id=#{@pf.id}"
    puts "pf.referenciacinep=#{@pf.referenciacinep}"
    @respgp = @pf.respgp
    puts "respgp=#{@respgp.id}"
    return if !@respgp || !@respgp.email
    puts "respgp.email=#{@respgp.email}"
    puts "enviando con tema #{@tiene}"
    mail(to: @respgp.email, 
         subject: "[CRECER] Proximamente un proyecto #{@tiene}")
  end

end