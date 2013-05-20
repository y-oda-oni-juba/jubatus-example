#include <iostream>
#include <string>
#include <utility>
#include <vector>

#include <jubatus/client.hpp>

using std::make_pair;
using std::pair;
using std::string;
using std::vector;
using jubatus::classifier::datum;
using jubatus::classifier::estimate_result;

datum make_datum(const string& hair, const string& top, const string& bottom, double height) {
  datum d;
  d.string_values.push_back(make_pair("hair", hair));
  d.string_values.push_back(make_pair("top", top));
  d.string_values.push_back(make_pair("bottom", bottom));

  d.num_values.push_back(make_pair("height", height));
  return d;
}

void parse_host_spec( const string &host_spec, string &host, int &port ) {
  size_t colon = host_spec.find(':');
  if ( colon != string::npos ) {
    host = host_spec.substr(0, colon);
    port = strtoul(host_spec.substr(colon+1).c_str(), NULL, 10);
  } else {
    host = host_spec;
  }
}

int main(int argc, char **argv) {
  string host = "127.0.0.1";
  int port = 9199;
  string name = "test";

  if ( argc > 1 ) parse_host_spec( argv[1], host, port );
  std::cerr << "connect to " << host << ":" << port << " ..." << std::endl;

  const int retry_max = 5;
  const int retry_interval = 3;

  jubatus::classifier::client::classifier client(host, port, 1.0);
  
  try {
    vector<pair<string, datum> > train_data;
    train_data.push_back(make_pair("male",   make_datum("short", "sweater", "jeans", 1.70)));
    train_data.push_back(make_pair("female", make_datum("long", "shirt", "skirt", 1.56)));
    train_data.push_back(make_pair("male",   make_datum("short", "jacket", "chino", 1.65)));
    train_data.push_back(make_pair("female", make_datum("short", "T shirt", "jeans", 1.72)));
    train_data.push_back(make_pair("male",   make_datum("long", "T shirt", "jeans", 1.82)));
    train_data.push_back(make_pair("female", make_datum("long", "jacket", "skirt", 1.43)));
    //train_data.push_back(make_pair("male",   make_datum("short", "jacket", "jeans", 1.76)));
    //train_data.push_back(make_pair("female", make_datum("long", "sweater", "skirt", 1.52)));
  
#define RPC_RETRY_EXCEPTION_COMMON_HANDLER()    \
    if ( ++retry_count >= retry_max ) throw;    \
                                                \
    client.get_client().close();                \
    std::cerr << e.what() << std::endl;         \
    ::sleep( retry_interval );                  \
    continue;

    int retry_count = 0; 
    while(true) {
      try {
        client.train(name, train_data);
      } catch( msgpack::rpc::timeout_error &e ) {
        RPC_RETRY_EXCEPTION_COMMON_HANDLER();
      } 
      catch( msgpack::rpc::connection_closed_error &e ) {   
        RPC_RETRY_EXCEPTION_COMMON_HANDLER();
      }
      break;
    }

    ::sleep(3);

    vector<datum> test_data;
    test_data.push_back(make_datum("short", "T shirt", "jeans", 1.81));
    test_data.push_back(make_datum("long", "shirt", "skirt", 1.50));

    vector<vector<estimate_result> > results;

    retry_count = 0;
    while(true) {
      try {
        results = client.classify(name, test_data);
      } catch( msgpack::rpc::timeout_error &e ) {
        RPC_RETRY_EXCEPTION_COMMON_HANDLER();
      } 
      catch( msgpack::rpc::connection_closed_error &e ) {   
        RPC_RETRY_EXCEPTION_COMMON_HANDLER();
      }
      break;
    }
  
    for (size_t i = 0; i < results.size(); ++i) {
      for (size_t j = 0; j < results[i].size(); ++j) {
        const estimate_result& r = results[i][j];
        std::cout << r.label << " " << r.score << std::endl;
      }
      std::cout << std::endl;
    }
  } catch( msgpack::rpc::rpc_error &e ) {
    std::cerr << e.what() << std::endl;
  }
}
