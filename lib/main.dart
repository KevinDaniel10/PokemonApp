import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokémon y Gatos Aleatorios',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PokemonList(),
      routes: {
        '/pokemon': (context) => const PokemonList(),
        '/cat': (context) => const CatList(),
        '/randomCat': (context) => const RandomCatCharacter(),
      },
    );
  }
}

class PokemonList extends StatefulWidget {
  const PokemonList({super.key});

  @override
  _PokemonListState createState() => _PokemonListState();
}

class _PokemonListState extends State<PokemonList> {
  List<Map<String, dynamic>> _pokemonList = [];
  bool _isLoading = false;
  String pokemon = '';
  int offset = 0;

  @override
  void initState() {
    super.initState();
    fetchPokemon();
  }

  Future<void> fetchPokemon({String? name, int offset = 0}) async {
    setState(() {
      _isLoading = true;
    });

    final url = name == null || name.isEmpty
        ? Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50&offset=$offset')
        : Uri.parse('https://pokeapi.co/api/v2/pokemon/$name');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> pokemonWithImages = [];

        if (name == null || name.isEmpty) {
          final List results = data['results'];
          for (var pokemon in results) {
            final detailsResponse = await http.get(Uri.parse(pokemon['url']));
            if (detailsResponse.statusCode == 200) {
              final detailsData = json.decode(detailsResponse.body);
              pokemonWithImages.add({
                'name': pokemon['name'],
                'image': detailsData['sprites']['front_default'],
              });
            }
          }
        } else {
          pokemonWithImages.add({
            'name': data['name'],
            'image': data['sprites']['front_default'],
          });
        }

        setState(() {
          _pokemonList = pokemonWithImages;
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Pokémon'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      const Text('Buscar Pokémon'),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText:
                                'Nombre o Posición en la Pokedex del Pokémon',
                          ),
                          onChanged: (value) {
                            setState(() {
                              pokemon = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          fetchPokemon(name: pokemon);
                          pokemon = '';
                        },
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(0, 0),
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    padding: const EdgeInsets.all(10),
                    itemCount: _pokemonList.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PokemonDetails(
                                name: _pokemonList[index]['name'],
                              ),
                            ),
                          );
                        },
                        child: Card(
                          color: Colors.blue[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                _pokemonList[index]['image'],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _pokemonList[index]['name'][0].toUpperCase() +
                                    _pokemonList[index]['name'].substring(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Pokémon #${offset + index + 1}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (offset > 1) {
                            offset -= 50;
                          }
                        });
                        fetchPokemon(offset: offset);
                      },
                      icon: const Icon(Icons.navigate_before),
                    ),
                    IconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/cat');
                        },
                        icon: const Icon(Icons.pets)),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (offset < 1000) {
                            offset += 50;
                          }
                        });
                        fetchPokemon(offset: offset);
                      },
                      icon: const Icon(Icons.navigate_next),
                    ),
                  ],
                )
              ],
            ),
    );
  }
}

class PokemonDetails extends StatelessWidget {
  PokemonDetails({super.key, required this.name});
  final String name;
  bool _isLoading = true;
  Map<String, dynamic> _pokemonDetails = {};

  Future<Map<String, dynamic>> fetchPokemonDetails() async {
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$name');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      }
    } catch (error) {
      print(error);
    } finally {
      _isLoading = false;
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder(
          future: fetchPokemonDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar los detalles'));
            } else if (snapshot.hasData) {
              _pokemonDetails = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.network(
                          _pokemonDetails['sprites']['front_default']),
                      const SizedBox(height: 20),
                      Text(
                        'Name: ${_pokemonDetails['name'][0].toUpperCase() + _pokemonDetails['name'].substring(1)}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Type: ${_pokemonDetails['types'][0]['type']['name']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Height: ${_pokemonDetails['height']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Weight: ${_pokemonDetails['weight']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      ..._pokemonDetails['stats'].map((stat) {
                        return Text(
                          'Stat: ${stat['stat']['name']} - ${stat['base_stat']}',
                          style: const TextStyle(fontSize: 16),
                        );
                      })
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: Text('No se encontro al Pokémon'));
            }
          }),
    );
  }
}

class CatList extends StatefulWidget {
  const CatList({super.key});

  @override
  _CatListState createState() => _CatListState();
}

class _CatListState extends State<CatList> {
  bool _isLoading = false;
  String catImage = '';

  @override
  void initState() {
    super.initState();
    fetchCatImage();
  }

  Future<void> fetchCatImage() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://api.thecatapi.com/v1/images/search');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          catImage = data[0]['url'];
        });
      }
    } catch (error) {
      print(error);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gatos Aleatorios'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // Se añade SingleChildScrollView
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.network(
                      catImage,
                      fit: BoxFit.cover,
                      height: MediaQuery.of(context).size.height * 0.5, // Controlar el tamaño
                    ),
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: fetchCatImage,
                    icon: const Icon(Icons.refresh),
                    iconSize: 40,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
    );
  }
}

class RandomCatCharacter extends StatelessWidget {
  const RandomCatCharacter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gato Aleatorio'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/cat');
          },
          child: const Text('Ver Gatos'),
        ),
      ),
    );
  }
}
