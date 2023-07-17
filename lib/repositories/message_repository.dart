import 'dart:convert';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:dartz/dartz.dart';

import '../models/Message.dart';

class MessageRepository {
  Future<Either<String, Message?>> sendMessage(Message message) async {
    try {
      final request = ModelMutations.create(message,
          authorizationMode: APIAuthorizationType.userPools);
      final response = await Amplify.API.mutate(request: request).response;
      return right(response.data);
    } on ApiException catch (e) {
      return left(e.message);
    }
  }

  Future<Either<String, List<Message>>> getMessages() async {
    try {
      final request = ModelQueries.list(Message.classType,
          limit: 4, authorizationMode: APIAuthorizationType.userPools);
      final response = await Amplify.API.mutate(request: request).response;
      final messages = response.data?.items.whereType<Message>().toList();
      if (messages != null) {
        messages.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
      }
      return right(messages ?? []);
    } on ApiException catch (e) {
      return left(e.message);
    }
  }

  Future<Either<String, List<Message>>> getLatestMessages() async {
    const graphQLDocument = '''query GetLatestMessages {
            messagesByDate(type: "Message" sortDirection: DESC limit: 20) {
              items {
                id
                message
                username
                type
                userId
                createdAt
              }
            }
          }''';

    try {
      final response = await Amplify.API
          .query(
            request: GraphQLRequest<String>(
                document: graphQLDocument,
                authorizationMode: APIAuthorizationType.userPools),
          )
          .response;

      if (response.data != null) {
        Map<String, dynamic> data = json.decode(response.data!);
        List items = data['messagesByDate']['items'];
        List<Message> messages =
            items.map((message) => Message.fromJson(message)).toList();
        return right(messages);
      }
      return right([]);
    } on ApiException catch (e) {
      return left(e.message);
    }
  }

  Stream<GraphQLResponse<Message>> subscribeToMessages() {
    final subscriptionRequest = ModelSubscriptions.onCreate(Message.classType,
        authorizationMode: APIAuthorizationType.userPools);
    final operation = Amplify.API.subscribe(
      subscriptionRequest,
      onEstablished: () => safePrint('Subscription established'),
    );
    return operation;
  }
}
