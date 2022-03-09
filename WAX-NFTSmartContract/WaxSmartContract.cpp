#include <eosio/eosio.hpp>
/* This contract creates a WAX NFT Sticker with the same author and owner account. Because the requireClaim flag is set to false, your smart contract account is charged the RAM and the asset is instantly assigned to the owner (you). */

 using namespace eosio;

 CONTRACT waxnft : public eosio::contract{
 public:
     using contract::contract;

     ACTION createnft() {

         //assign asset attributes
         name author = get_self();
         name category = "WAX_NFTs"_n;
         name owner = "Ayed"_n;
         //idata includes key/value pairs that can not change.
         std::string idata = R"json({"name": "First NFT Test", "desc" : "First NFT Creation Test on WAX" })json";
         //mdata includes key/value pairs that you can update.
         std::string mdata = R"json({"color": "black", "img" : "https://developer.wax.io/img/wax_sticker.png" })json";
         bool requireClaim = false;

         //call the simpleassets create action
         action(
             { author, "active"_n },
             "simpleassets"_n,
             "create"_n,
             std::tuple(author, category, owner, idata, mdata, requireClaim)
         )
         .send();

     }
 };

 EOSIO_DISPATCH(waxnft, (createnft))
