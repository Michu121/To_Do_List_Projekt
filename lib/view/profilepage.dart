import 'package:flutter/material.dart';


class ProfilePage extends StatefulWidget{
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage>{
  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
        'Login',
        style: TextStyle(
          fontSize: 35,
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold
        ),
        ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Form(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                                    onChanged: (String value) {

                                    },
                                    validator: (value) {
                        return value!.isEmpty ? 'Podaj adres email' : null;
                                    }
                      ),
                  ),

                  SizedBox(height:30,),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.password),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (String value) {

                        },
                        validator: (value) {
                          return value!.isEmpty ? 'Podaj adres email' : null;
                        }
                    ),
                  ),
                  SizedBox(height: 30,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: MaterialButton(
                      minWidth: double.infinity,
                      onPressed: () {
                        Text('Login');
                      },
                      child: Text('Login'),
                      color: Colors.blueAccent,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      );
  }
}