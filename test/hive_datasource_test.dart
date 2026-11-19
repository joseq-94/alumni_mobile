import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:alumni_mobile/services/hive_datasource.dart';
import 'package:alumni_mobile/services/alumni_datasource.dart';

void main() {
  test(
    'Hive keeps edits and feed after closing and reopening the database',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'alumni_hive_test_',
      );
      Hive.init(directory.path);
      try {
        var source = await HiveDataSource.createAsync();
        await expectLater(
          source.signIn('admin', 'wrong'),
          throwsA(isA<DataSourceException>()),
        );
        expect((await source.signIn('admin', 'Password1')).name, 'admin');
        await source.updateProfile('Updated admin', 'Saved in Hive');
        final firstPage = await source.readFeed(1);
        expect(firstPage.posts.length, 20);
        expect((await source.readFeed(2)).posts.length, 10);
        await source.close();

        source = await HiveDataSource.createAsync();
        await expectLater(
          source.readProfile(),
          throwsA(isA<DataSourceException>()),
        );
        final profile = await source.signIn('admin', 'Password1');
        expect(profile.name, 'Updated admin');
        expect(profile.bio, 'Saved in Hive');
        expect(
          (await source.readPost(firstPage.posts.first.id)).title,
          firstPage.posts.first.title,
        );
        expect(Hive.box('alumni_posts').length, 30);
        await source.signOut();
        expect(
          (await source.signIn('sam@example.com', 'Password1')).name,
          'Sam Taylor',
        );
        await source.close();
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
