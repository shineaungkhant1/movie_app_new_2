import 'package:movie_app/data/models/movie_model.dart';
import 'package:movie_app/data/vos/actor_vo.dart';
import 'package:movie_app/data/vos/genre_vo.dart';
import 'package:movie_app/data/vos/movie_vo.dart';
import 'package:movie_app/network/dataagents/movie_data_agent.dart';
import 'package:movie_app/network/dataagents/retrofit_data_agent_impl.dart';
import 'package:movie_app/persistence/daos/actor_dao.dart';
import 'package:movie_app/persistence/daos/genre_dao.dart';
import 'package:movie_app/persistence/daos/movie_dao.dart';
import 'package:stream_transform/stream_transform.dart';

class MovieModelImpl extends MovieModel {
  MovieDataAgent mDataAgent = RetrofitDataAgentImpl();

  static final MovieModelImpl _singleton = MovieModelImpl._internal();

  factory MovieModelImpl() {
    return _singleton;
  }

  MovieModelImpl._internal(){
    getNowPlayingMoviesFromDatabase();
    getTopRatedMoviesFromDatabase();
    getPopularMoviesFromDatabase();
    getActors(1);
    getAllActorsFromDatabase();
    getGenres();
    getGenresFromDatabase();
  }

  /// Daos
  MovieDao mMovieDao = MovieDao();
  GenreDao mGenreDao = GenreDao();
  ActorDao mActorDao = ActorDao();

  ///Home Page State Variables
  List<MovieVO>? mNowPlayingMoviesList;
  List<MovieVO>? mPopularMoviesList;
  List<MovieVO>? mShowCaseMovieList;
  List<MovieVO>? mMoviesByGenreList;
  List<GenreVO>? mGenreList;
  List<ActorVO>? mActors;

  ///Movie Details Page State Variables
  MovieVO? mMovie;
  List<ActorVO>? mActorsList;
  List<ActorVO>? mCreatorsList;

  /// Network
  @override
  Future<List<ActorVO>> getActors(int page) {
    return mDataAgent.getActors(page).then((actors) async {
      mActorDao.saveAllActors(actors!);
      mActors = actors;
      notifyListeners();
      return Future.value(actors);
    });
  }

  @override
  void getGenres() {
     mDataAgent.getGenres().then((genres) async {
      mGenreDao.saveAllGenres(genres!);
      mGenreList = genres;
      getMoviesByGenre(genres.first.id);
      notifyListeners();
      return Future.value(genres);
    });
  }

  @override
  void getNowPlayingMovies(int page) {
    mDataAgent.getNowPlayingMovie(page).then((movies) async {
      List<MovieVO>? nowPlayingMovies = movies?.map((movie) {
        movie.isTopRated = false;
        movie.isNowPlaying = true;
        movie.isPopular = false;
        return movie;
      }).toList();
      mMovieDao.saveMovies(nowPlayingMovies!);
      mNowPlayingMoviesList = nowPlayingMovies;
      notifyListeners();
    });
  }

  @override
  void getTopRatedMovies(int page) {
    mDataAgent.getTopRatedMovies(page).then((movies) async {
      List<MovieVO>? topRatedMovies = movies?.map((movie) {
        movie.isTopRated = true;
        movie.isNowPlaying = false;
        movie.isPopular = false;
        return movie;
      }).toList();
      mMovieDao.saveMovies(topRatedMovies!);
      mShowCaseMovieList = topRatedMovies;
      notifyListeners();
    });
  }

  @override
  void getPopularMovies(int page) {
    mDataAgent.getPopularMovies(page).then((movies) async {
      List<MovieVO>? popularMovies = movies?.map((movie) {
        movie.isTopRated = false;
        movie.isNowPlaying = false;
        movie.isPopular = true;
        return movie;
      }).toList();
      mMovieDao.saveMovies(popularMovies!);
      mPopularMoviesList = popularMovies;
      notifyListeners();
    });
  }



  @override
  void getCreditsByMovie(int movieId) {
     mDataAgent.getCreditsByMovie(movieId)
         .then((creditsList){
       this.mActorsList = creditsList.first;
       this.mCreatorsList = creditsList[1];
       notifyListeners();
     });
  }

  @override
  void getMovieDetails(int movieId) {
     mDataAgent.getMovieDetails(movieId).then((movie) async {
      mMovieDao.saveSingleMovie(movie!);
      mMovie = movie;
      notifyListeners();
      return Future.value(movie);
    });
  }

  /// Database
  @override
  void getAllActorsFromDatabase() {
     mActors = mActorDao.getAllActors();
     notifyListeners();
  }

  @override
  void getGenresFromDatabase() {
     mGenreList = mGenreDao.getAllGenres();
     notifyListeners();
  }

  @override
  void getMovieDetailsFromFromDatabase(int movieId) {
     mMovie = mMovieDao.getMovieById(movieId);
     notifyListeners();
  }

  @override
  void getNowPlayingMoviesFromDatabase() {
    this.getNowPlayingMovies(1);
     mMovieDao
        .getAllMoviesEventStream()
        .startWith(mMovieDao.getNowPlayingMoviesStream())
        .combineLatest(mMovieDao.getNowPlayingMoviesStream(), (event, movieList) => movieList as List<MovieVO>)
    .first
    .then((nowPlayingMovies){
      mNowPlayingMoviesList = nowPlayingMovies;
      notifyListeners();
    });
  }

  @override
  void getPopularMoviesFromDatabase() {
    this.getPopularMovies(1);
     mMovieDao
        .getAllMoviesEventStream()
        .startWith(mMovieDao.getPopularMoviesStream())
        .combineLatest(mMovieDao.getPopularMoviesStream(), (event, movieList) => movieList as List<MovieVO>)
        .first
        .then((popularMovies){
      mPopularMoviesList = popularMovies;
      notifyListeners();
    });
  }



  @override
  void getMoviesByGenre(int genreId) {
    mDataAgent.getMoviesByGenre(genreId).then((movieList) {
      mMoviesByGenreList = movieList;
      notifyListeners();
    });
  }

  @override
  void getTopRatedMoviesFromDatabase() {
    this.getTopRatedMovies(1);
     mMovieDao
        .getAllMoviesEventStream()
        .startWith(mMovieDao.getTopRatedMoviesStream())
        .combineLatest(mMovieDao.getTopRatedMoviesStream(), (event, movieList) => movieList as List<MovieVO>)
        .first
        .then((topRatedMovies){
      mShowCaseMovieList = topRatedMovies;
      notifyListeners();
    });
  }


}
