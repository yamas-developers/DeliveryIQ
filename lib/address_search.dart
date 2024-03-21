import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_places_flutter/place_service.dart';

class AddressSearch extends SearchDelegate<Suggestion> {
  AddressSearch(this.sessionToken) {
    apiClient = PlaceApiProvider(sessionToken);
  }

  final sessionToken;
  late PlaceApiProvider apiClient;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Clear',
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, Suggestion('', ''));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: query == ""
          ? null
          : apiClient.fetchSuggestions(
              query, Localizations.localeOf(context).languageCode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log('erro : ${snapshot.error}');
          return Text('has error');
        }
        return query == ''
            ? Container(
                padding: EdgeInsets.all(16.0),
                child: Text('Enter your address'),
              )
            : snapshot.hasData
                ? ListView.builder(
                    itemBuilder: (context, index) => ListTile(
                      title: Text(
                          (snapshot.data![index] as Suggestion).description),
                      onTap: () {
                        close(context, snapshot.data![index] as Suggestion);
                      },
                    ),
                    itemCount: snapshot.data!.length,
                  )
                : Container(child: Text('Loading...'));
      },
    );
  }
}
