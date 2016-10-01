class ProdutosController < ApplicationController
    #convert BRL to BTC https://blockchain.info/tobtc?currency=BRL&value=VALOR DO PRODUTO
    require 'net/http'
    require 'uri'
    require 'net/https'
    require 'json'
    require 'block_io'
    before_action :require_user, only: [:show, :solicitar_pagamento]
    BlockIo.set_options :api_key=> 'ac35-6ff5-e103-d1c3', :pin => 'Xatm@074', :version => 2
    
    def list_all_payment
         @pagamento = Pagamento.find_by(address: params[:id])
         @endereco = @pagamento.endereco
         @produtos = @pagamento.produtos
         @vol = @pagamento.volume
         @carteira = @pagamento.address
        
    end
    def finalizar_compra
       pgto = Pagamento.new(pagamento_params)
       url = 'https://block.io/api/v2/get_new_address/?api_key=ac35-6ff5-e103-d1c3'
       uri = URI(url)
       response = Net::HTTP.get(uri)
       hash = JSON.parse(response)
       @transaction_status = hash["status"].to_s
       net =  hash["data"]["network"].to_s
       userid = hash["data"]["user_id"].to_s
       @payment_address = hash["data"]["address"]
       @identifier = hash["data"]["label"].to_s
       puts @payment_address
       
       
       notifyurl = 'https://block.io/api/v2/create_notification/?api_key=ac35-6ff5-e103-d1c3&type=address&address=' + @payment_address + '&url=http://bmarkets.herokuapp.com/blckrntf'
       #resposta = Net::HTTP.get('https://block.io/api/v2/create_notification/?api_key=ac35-6ff5-e103-d1c3&type=address&address=' + @payment_address + '&url=https://bmarket-rbm4.c9users.io/blckrntf')
       notifyuri = URI(notifyurl)
       response2 = Net::HTTP.get(notifyuri)
       hashntf = JSON.parse(response2)
       puts hashntf
       salvar_pagamento(:user_id => userid, :network => net, :address => @payment_address, :label => @identifier, :volume => pgto.volume, :usuario => pgto.usuario, :status => @transaction_status, :endereco => pgto.endereco, :produtos => pgto.produtos, :postcode => pgto.postcode)
    end
    private
    def salvar_pagamento(pagamento_params)
        pagamento = Pagamento.new(pagamento_params)
        pagamento.save
        session[:order_id] = nil
        @messages = 'Order has been placed successfully!'
        puts @messages
    end
    def endereco_params
        params.require(:pagamento).permit(:address)
    end
    
    def pagamento_params
        params.require(:pagamento).permit(:user_id,:network, :address, :label, :volume, :usuario, :endereco, :produtos, :postcode)
    end
end
